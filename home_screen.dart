import 'package:flutter/material.dart';
import 'package:habit_flow/api_service.dart'; // Make sure you import the API service
import 'package:habit_flow/habit_detail_screen.dart'; // Make sure to import HabitDetailScreen
import 'package:habit_flow/habit_model.dart'; // Import the Habit model

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final APIService apiService = APIService(); // API service instance
  List<Habit> habitList = []; // List to store fetched habits

  @override
  void initState() {
    super.initState();
    _fetchHabits(); // Fetch habits when the screen loads
  }

  // Function to fetch habits from the API
  void _fetchHabits() async {
    try {
      final habits = await apiService
          .fetchHabits(); // Fetch habits using the API service
      setState(() {
        habitList = habits
            .map((habit) => Habit.fromJson(habit))
            .toList(); // Map fetched data to Habit model
      });
    } catch (e) {
      print('Error fetching habits: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HabitFlow")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Navigate to Add/Edit Habit Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEditHabitScreen()),
              ).then(
                (_) => _fetchHabits(),
              ); // Refresh the habit list after adding a new habit
            },
            child: const Text('Add Habit'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: habitList.length,
              itemBuilder: (context, index) {
                final habit = habitList[index];
                return ListTile(
                  title: Text(habit.name),
                  subtitle: Text('Frequency: ${habit.frequency}'),
                  onTap: () {
                    // Navigate to the HabitDetailScreen when tapping on a habit
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HabitDetailScreen(
                          habitKey: habit.id,
                        ), // Pass habit ID to the detail screen
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
