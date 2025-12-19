import 'dart:convert';
import 'package:http/http.dart' as http;

class APIService {
  final String baseUrl =
      'https://example.com/api/habits'; // Replace with your API URL

  // Function to fetch habits from the API
  Future<List<dynamic>> fetchHabits() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      return json.decode(response.body); // Return parsed list of habits
    } else {
      throw Exception('Failed to load habits');
    }
  }

  // Function to add a new habit to the API
  Future<void> addHabit(String name, String frequency, String icon) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'frequency': frequency, 'icon': icon}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create habit');
    }
  }

  // Function to edit an existing habit in the API
  Future<void> updateHabit(
    String habitId,
    String name,
    String frequency,
    String icon,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$habitId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'frequency': frequency, 'icon': icon}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update habit');
    }
  }
}
