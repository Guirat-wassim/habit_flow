import 'package:flutter/material.dart';
import 'package:habitflow/api_service.dart'; // Import the APIService
import 'package:habitflow/model/habit_model.dart'; // Import Habit model

class AddEditHabitScreen extends StatefulWidget {
  final String? habitKey; // Optional habitKey for editing
  AddEditHabitScreen({this.habitKey});

  @override
  _AddEditHabitScreenState createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController iconController = TextEditingController();

  final APIService apiService = APIService(); // Instance of APIService

  @override
  void initState() {
    super.initState();

    if (widget.habitKey != null) {
      // If editing, fetch the habit data
      _loadHabit();
    }
  }

  // Load habit details for editing
  void _loadHabit() {
    // Fetch the habit using the habitKey
    // You'll need to fetch the habit data from your local database or API
    // For now, we're assuming it is available
  }

  // Function to save or update the habit
  void _saveHabit() async {
    if (widget.habitKey == null) {
      // If adding a new habit, send data to API
      await apiService.addHabit(
        nameController.text,
        frequencyController.text,
        iconController.text,
      );
    } else {
      // If editing, update the habit via API
      await apiService.updateHabit(
        widget.habitKey!,
        nameController.text,
        frequencyController.text,
        iconController.text,
      );
    }
    Navigator.pop(context); // Go back to previous screen after saving
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habitKey == null ? 'Add Habit' : 'Edit Habit'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Habit Name'),
            ),
            TextField(
              controller: frequencyController,
              decoration: InputDecoration(labelText: 'Frequency'),
            ),
            TextField(
              controller: iconController,
              decoration: InputDecoration(labelText: 'Icon'),
            ),
            ElevatedButton(onPressed: _saveHabit, child: Text('Save Habit')),
          ],
        ),
      ),
    );
  }
}
