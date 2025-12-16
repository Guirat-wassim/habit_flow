import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

// HabitFormScreen Widget for adding/editing habits
class HabitFormScreen extends StatefulWidget {
  final Habit? existing;

  const HabitFormScreen({super.key, this.existing});

  @override
  _HabitFormScreenState createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  int _colorValue = Colors.blue.value;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _iconController.text = widget.existing!.icon;
      _colorValue = widget.existing!.colorValue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _saveHabit() {
    if (_nameController.text.isNotEmpty && _iconController.text.isNotEmpty) {
      final habit = Habit(
        id:
            widget.existing?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        icon: _iconController.text,
        colorValue: _colorValue,
        doneDays: widget.existing?.doneDays ?? {},
      );
      Navigator.pop(context, habit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Habit' : 'Edit Habit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Habit Name'),
            ),
            TextField(
              controller: _iconController,
              decoration: const InputDecoration(labelText: 'Icon (Emoji)'),
            ),
            const SizedBox(height: 20),
            Text("Pick a Color"),
            Row(
              children: [
                ColorPickerButton(Colors.blue, _colorValue, () {
                  setState(() {
                    _colorValue = Colors.blue.value;
                  });
                }),
                ColorPickerButton(Colors.green, _colorValue, () {
                  setState(() {
                    _colorValue = Colors.green.value;
                  });
                }),
                ColorPickerButton(Colors.red, _colorValue, () {
                  setState(() {
                    _colorValue = Colors.red.value;
                  });
                }),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveHabit,
              child: Text(
                widget.existing == null ? "Add Habit" : "Save Changes",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorPickerButton extends StatelessWidget {
  final Color color;
  final int currentColor;
  final VoidCallback onTap;

  const ColorPickerButton(
    this.color,
    this.currentColor,
    this.onTap, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: color,
        child: currentColor == color.value
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }
}
