import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import 'habit_form_screen.dart'; // Importing the HabitFormScreen for new habit creation

// Habit class to handle habit data
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
      id: m['id'] as String,
      name: m['name'] as String,
      colorValue: m['colorValue'] as int,
      icon: m['icon'] as String,
      doneDays: map,
    );
  }
}

// Hive Service to handle data storage
class HiveService {
  static const String habitsBoxName = 'habitsBox';
  static const String settingsBoxName = 'settingsBox';

  static Future<void> init() async {
    await Hive.initFlutter();
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
      if (value is Map) {
        list.add(Habit.fromMap(value));
      }
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

// HomeScreen widget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> _habits = [];
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _darkMode = HiveService.loadDarkMode();
    _loadHabits();
  }

  void _loadHabits() {
    final list = HiveService.loadHabits();
    setState(() => _habits = list);
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

  // Settings Screen for dark mode toggle
  Widget _buildSettingsScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SwitchListTile(
        title: const Text("Dark Mode"),
        value: _darkMode,
        onChanged: (value) {
          setState(() {
            _darkMode = value;
            HiveService.saveDarkMode(value); // Save dark mode in hive
          });
        },
      ),
    );
  }

  // Navigate to Statistics screen
  void _navigateToStatisticsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatisticsScreen(habits: _habits)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = _todayPercent();

    return Scaffold(
      appBar: AppBar(
        title: const Text("HabitFlow"),
        actions: [
          IconButton(
            onPressed:
                _navigateToStatisticsScreen, // Navigate to StatisticsScreen
            icon: const Icon(Icons.bar_chart),
            tooltip: "Statistics",
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _buildSettingsScreen(),
                ), // Settings screen
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: "Settings",
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
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_outline, size: 60),
                    SizedBox(height: 12),
                    Text("No habits yet.\nTap + to add your first habit!"),
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
                        final key = dateKey(DateTime.now());
                        final done = h.doneDays[key] == true;

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

  void _editHabit(Habit h) {}

  void _deleteHabit(Habit h) {}
}

void _toggleDone(Habit h, bool v) {}

class StatisticsScreen extends StatelessWidget {
  final List<Habit> habits;
  const StatisticsScreen({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: Center(child: Text("Statistics data here...")),
    );
  }
}

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
      body: SwitchListTile(
        title: const Text("Dark Mode"),
        value: darkMode,
        onChanged: onThemeChanged,
      ),
    );
  }
}

String dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return "$y-$m-$day";
}
