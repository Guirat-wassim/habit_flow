import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HiveService.init();
  runApp(const HabitFlowApp());
}

class HabitFlowApp extends StatefulWidget {
  const HabitFlowApp({super.key});

  @override
  State<HabitFlowApp> createState() => _HabitFlowAppState();
}

class _HabitFlowAppState extends State<HabitFlowApp> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _darkMode = HiveService.loadDarkMode();
  }

  void _setDarkMode(bool v) async {
    await HiveService.saveDarkMode(v);
    setState(() => _darkMode = v);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HabitFlow',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: _darkMode ? Brightness.dark : Brightness.light,
        useMaterial3: true,
      ),
      home: SplashScreen(onReady: () {}),
      routes: {
        "/home": (_) =>
            HomeScreen(darkMode: _darkMode, onThemeChanged: _setDarkMode),
      },
    );
  }
}

// -------------------- SPLASH --------------------

class SplashScreen extends StatefulWidget {
  final VoidCallback onReady;
  const SplashScreen({super.key, required this.onReady});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      widget.onReady();
      Navigator.pushReplacementNamed(context, "/home");
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "HabitFlow",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text("Daily Habit Tracker"),
          ],
        ),
      ),
    );
  }
}

// -------------------- MODEL --------------------

class Habit {
  String id;
  String name;
  int colorValue;
  String icon;
  Map<String, bool> doneDays;

  Habit({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.icon,
    Map<String, bool>? doneDays,
  }) : doneDays = doneDays ?? {};

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'icon': icon,
    'doneDays': doneDays,
  };

  static Habit fromMap(Map<dynamic, dynamic> m) {
    final raw = m['doneDays'];
    final Map<String, bool> map = {};
    if (raw is Map) {
      for (final e in raw.entries) {
        map[e.key.toString()] = e.value == true;
      }
    }
    return Habit(
      id: (m['id'] ?? "") as String,
      name: (m['name'] ?? "") as String,
      colorValue: (m['colorValue'] ?? Colors.blue.value) as int,
      icon: (m['icon'] ?? "✅") as String,
      doneDays: map,
    );
  }
}

// -------------------- HIVE SERVICE --------------------

class HiveService {
  static const String habitsBoxName = 'habitsBox';
  static const String settingsBoxName = 'settingsBox';

  static Future<void> init() async {
    await Hive.openBox(habitsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box get habitsBox => Hive.box(habitsBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);

  static List<Habit> loadHabits() {
    final box = habitsBox;
    final List<Habit> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) list.add(Habit.fromMap(value));
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static Future<void> saveHabit(Habit habit) async {
    await habitsBox.put(habit.id, habit.toMap());
  }

  static Future<void> deleteHabit(String id) async {
    await habitsBox.delete(id);
  }

  static bool loadDarkMode() {
    return settingsBox.get('darkMode', defaultValue: false) == true;
  }

  static Future<void> saveDarkMode(bool value) async {
    await settingsBox.put('darkMode', value);
  }
}

// -------------------- HOME --------------------

class HomeScreen extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  void _loadHabits() {
    setState(() => _habits = HiveService.loadHabits());
  }

  double _todayPercent() {
    if (_habits.isEmpty) return 0;
    final k = dateKey(DateTime.now());
    final done = _habits.where((h) => h.doneDays[k] == true).length;
    return done / _habits.length;
  }

  Future<void> _addHabit() async {
    final result = await Navigator.push<Habit>(
      context,
      MaterialPageRoute(builder: (_) => const HabitFormScreen()),
    );
    if (result == null) return;
    await HiveService.saveHabit(result);
    _loadHabits();
  }

  Future<void> _editHabit(Habit habit) async {
    final result = await Navigator.push<Habit>(
      context,
      MaterialPageRoute(builder: (_) => HabitFormScreen(existing: habit)),
    );
    if (result == null) return;
    await HiveService.saveHabit(result);
    _loadHabits();
  }

  Future<void> _deleteHabit(Habit habit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete habit?"),
        content: Text("Are you sure you want to delete '${habit.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await HiveService.deleteHabit(habit.id);
    _loadHabits();
  }

  Future<void> _toggleDone(Habit habit, bool value) async {
    final k = dateKey(DateTime.now());
    habit.doneDays[k] = value;
    await HiveService.saveHabit(habit);
    _loadHabits();

    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${habit.name} done! ${randomQuote()}"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = _todayPercent();

    return Scaffold(
      appBar: AppBar(
        title: const Text("HabitFlow"),
        actions: [
          IconButton(
            tooltip: "Statistics",
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatisticsScreen(habits: _habits),
                ),
              );
            },
          ),
          IconButton(
            tooltip: "Settings",
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    darkMode: widget.darkMode,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
              _loadHabits();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _habits.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 60),
                    SizedBox(height: 12),
                    Text(
                      "No habits yet.\nTap + to add your first habit!",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today progress: ${(percent * 100).round()}%",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: percent),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _habits.length,
                      itemBuilder: (context, i) {
                        final h = _habits[i];
                        final k = dateKey(DateTime.now());
                        final done = h.doneDays[k] == true;

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(h.colorValue),
                              child: Text(h.icon),
                            ),
                            title: Text(h.name),
                            subtitle: Text(
                              done ? "Completed today ✅" : "Not done yet",
                            ),
                            trailing: Checkbox(
                              value: done,
                              onChanged: (v) {
                                if (v == null) return;
                                _toggleDone(h, v);
                              },
                            ),
                            onTap: () => _editHabit(h),
                            onLongPress: () => _deleteHabit(h),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Tip: Tap a habit to edit. Long-press to delete.",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}

// -------------------- HABIT FORM --------------------

class HabitFormScreen extends StatefulWidget {
  final Habit? existing;
  const HabitFormScreen({super.key, this.existing});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  int _colorValue = Colors.blue.value;
  String _icon = "✅";

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _colorValue = e.colorValue;
      _icon = e.icon;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final doneDays = widget.existing?.doneDays ?? <String, bool>{};

    final habit = Habit(
      id: id,
      name: _nameCtrl.text.trim(),
      colorValue: _colorValue,
      icon: _icon,
      doneDays: doneDays,
    );

    Navigator.pop(context, habit);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Habit" : "Add Habit")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Habit name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return "Please enter a habit name";
                  if (v.trim().length < 2) return "Name too short";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _icon,
                decoration: const InputDecoration(
                  labelText: "Icon",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "✅", child: Text("✅ Check")),
                  DropdownMenuItem(value: "💧", child: Text("💧 Water")),
                  DropdownMenuItem(value: "🏃", child: Text("🏃 Run")),
                  DropdownMenuItem(value: "📚", child: Text("📚 Study")),
                  DropdownMenuItem(value: "🧘", child: Text("🧘 Meditation")),
                ],
                onChanged: (v) => setState(() => _icon = v ?? "✅"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _colorValue,
                decoration: const InputDecoration(
                  labelText: "Color",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 0xFF2196F3, child: Text("Blue")),
                  DropdownMenuItem(value: 0xFF4CAF50, child: Text("Green")),
                  DropdownMenuItem(value: 0xFFFF9800, child: Text("Orange")),
                  DropdownMenuItem(value: 0xFF9C27B0, child: Text("Purple")),
                  DropdownMenuItem(value: 0xFFF44336, child: Text("Red")),
                ],
                onChanged: (v) =>
                    setState(() => _colorValue = v ?? Colors.blue.value),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- SETTINGS --------------------

class SettingsScreen extends StatelessWidget {
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: darkMode,
            onChanged: (v) => onThemeChanged(v),
          ),
        ],
      ),
    );
  }
}

// -------------------- STATS --------------------

class StatisticsScreen extends StatelessWidget {
  final List<Habit> habits;
  const StatisticsScreen({super.key, required this.habits});

  int _todayDoneCount() {
    final k = dateKey(DateTime.now());
    return habits.where((h) => h.doneDays[k] == true).length;
  }

  double _todayPercent() {
    if (habits.isEmpty) return 0;
    return _todayDoneCount() / habits.length;
  }

  int _currentStreakForHabit(Habit h) {
    int streak = 0;
    DateTime d = startOfDay(DateTime.now());
    while (true) {
      final k = dateKey(d);
      if (h.doneDays[k] == true) {
        streak++;
        d = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  void _showWeeklyRecap(BuildContext context) {
    final today = DateTime.now();
    final start = startOfWeekMonday(today);
    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    int totalChecks = 0;
    int totalPossible = habits.length * 7;

    for (final d in days) {
      final k = dateKey(d);
      for (final h in habits) {
        if (h.doneDays[k] == true) totalChecks++;
      }
    }

    final percent = totalPossible == 0
        ? 0
        : (totalChecks / totalPossible * 100).round();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Weekly Recap"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Habits: ${habits.length}"),
            Text("Total completed checks: $totalChecks"),
            Text("Weekly score: $percent%"),
            const SizedBox(height: 10),
            const Text("Tip: try to keep a steady streak 😉"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayPercent = _todayPercent();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
        actions: [
          IconButton(
            onPressed: () => _showWeeklyRecap(context),
            icon: const Icon(Icons.insights),
            tooltip: "Weekly Recap",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: habits.isEmpty
            ? const Center(child: Text("No habits yet. Add one from Home."))
            : ListView(
                children: [
                  Text(
                    "Today progress: ${(todayPercent * 100).round()}%",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: todayPercent),
                  const SizedBox(height: 20),
                  const Text(
                    "Streaks",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...habits.map((h) {
                    final streak = _currentStreakForHabit(h);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(h.colorValue),
                        child: Text(h.icon),
                      ),
                      title: Text(h.name),
                      subtitle: Text("Current streak: $streak day(s)"),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}

// -------------------- HELPERS --------------------

String dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return "$y-$m-$day";
}

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime startOfWeekMonday(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  final weekday = day.weekday; // Mon=1..Sun=7
  return day.subtract(Duration(days: weekday - 1));
}

String randomQuote() {
  final quotes = [
    "Small steps every day.",
    "Consistency beats motivation.",
    "Progress, not perfection.",
    "You’re building a habit!",
    "Keep going — future you will thank you.",
  ];
  return quotes[Random().nextInt(quotes.length)];
}
