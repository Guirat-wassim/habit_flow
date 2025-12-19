import 'package:hive/hive.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 1)
class Habit {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String frequency;

  @HiveField(2)
  final String icon;

  @HiveField(3)
  final String key; // Add a key field

  Habit({
    required this.name,
    required this.frequency,
    required this.icon,
    required this.key,
  });

  // Method to create a Habit instance from JSON (for API responses)
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      name: json['name'],
      frequency: json['frequency'],
      icon: json['icon'],
      key: json['id']
          .toString(), // Assuming there's an 'id' field in the response
    );
  }

  // Method to convert a Habit instance to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'frequency': frequency,
      'icon': icon,
      'id': key, // Assuming there's an 'id' field for the API
    };
  }
}
