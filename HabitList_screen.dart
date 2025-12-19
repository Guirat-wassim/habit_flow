import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habitflow/model/habit_model.dart'; // Import Habit model
import 'habit_detail_screen.dart'; // Import HabitDetailScreen to navigate to it

class HabitListScreen extends StatefulWidget {
  @override
  _HabitListScreenState createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  late Box habitBox;
  List<Habit> habitList = [];

  @override
  void initState() {
    super.initState();
    _openBox(); // Open the box when the screen is initialized
  }

  // Method to open the Hive box
  void _openBox() async {
    habitBox = await Hive.openBox('habitBox'); // Open the box
    setState(() {
      habitList = habitBox.values.toList().cast<Habit>(); // Fetch data from box
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Habit List')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: habitList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(habitList[index].name),
                  subtitle: Text(habitList[index].frequency),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HabitDetailScreen(habitKey: habitList[index].key),
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
