import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // For UI components like ScaffoldMessenger
import 'package:http/http.dart' as http; // For HTTP requests
import 'dart:convert'; // For jsonEncode() and jsonDecode()
import 'package:shared_preferences/shared_preferences.dart'; // For SharedPreferences


final TextEditingController emailController = TextEditingController();
final TextEditingController passwordController = TextEditingController();

Future<void> _login(BuildContext context) async {

  final String apiUrl = "http://localhost:5000/api/user/login";

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text.trim(),
        "password": passwordController.text.trim()
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // ✅ Save email in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', responseData['email']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'])),
      );

      // Navigate to Home Page
      Navigator.pushNamed(context, '/homepage');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'] ?? 'Login failed')),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  }
}
