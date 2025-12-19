import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_flow/model/habit_model.dart'; // Ensure the habit model is imported correctly
import 'package:habit_flow/habit_form_screen.dart'; // Make sure the Add/Edit screen is imported

class HabitDetailScreen extends StatelessWidget {
  final String habitKey;

  HabitDetailScreen({required this.habitKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Habit Detail')),
      body: FutureBuilder(
        future: Hive.openBox('habitBox'), // Open the box that stores habits
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            var habitBox = snapshot.data as Box;
            Habit? habit = habitBox.get(
              habitKey,
            ); // Get the habit using the habitKey

            if (habit == null) {
              return Center(child: Text('No habit found.'));
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Name: ${habit.name}'),
                  Text('Frequency: ${habit.frequency}'),
                  Text('Icon: ${habit.icon}'),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the Add/Edit screen to edit the habit
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddEditHabitScreen(habitKey: habitKey),
                        ),
                      );
                    },
                    child: Text('Edit Habit'),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
