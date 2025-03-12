import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotePage extends StatefulWidget {
  final List<String> categories;
  final Map<String, dynamic>? existingNote;

  NotePage({required this.categories, this.existingNote});

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  TextEditingController _titleController = TextEditingController();
  String _selectedCategory = "All";
  Color _selectedColor = Colors.yellow;
  bool _isLoading = false;

  final String apiUrl = "http://localhost:5000/api/notes"; 
  final String userId = "67cac46f8f92ef9eccd39a0b"; // Replace with actual user ID
  final String token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiI2N2NhYzQ2ZjhmOTJlZjllY2NkMzlhMGIiLCJlbWFpbCI6ImJob29taTEwMEBnbWFpbC5jb20iLCJpYXQiOjE3NDEzNDE4MDcsImV4cCI6MTc1Njg5MzgwNywiaXNzIjoidGVjaG55a3MuY29tIn0.Go6qC97zv2orpwOGjQh1nUDrxYc0gR59rSTadp4N-zM"; // Replace with actual JWT token

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!['title'];
      _selectedCategory = widget.existingNote!['category'];
      _selectedColor = Color(int.parse(widget.existingNote!['color'], radix: 16));
    }
  }
Future<void> _saveNote() async {
  setState(() {
    _isLoading = true; // Show loading
  });

   Map<String, dynamic> note = {
      'userId': "67cac46f8f92ef9eccd39a0b", // Added user ID
      'title': _titleController.text,
      'category': _selectedCategory,
      'color': _selectedColor.value.toRadixString(16), // Store color as hex
    };

  try {
    final response = await http.post(
      Uri.parse("http://localhost:5000/api/notes"), // Update URL
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer YOUR_JWT_TOKEN", // Add token here
      },
      body: jsonEncode(note),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      print("Note Created Successfully");
      Navigator.pop(context, note);
    } else {
      _showErrorDialog("Failed to create note. Try again.");
    }
  } catch (error) {
    _showErrorDialog("Network error. Please check your connection.");
  }

  setState(() {
    _isLoading = false;
  });
}

void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("Error"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text("OK"),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingNote == null ? "New Note" : "Edit Note"),
        actions: [
          IconButton(
            icon: Icon(Icons.check,color: const Color.fromARGB(255, 255, 255, 255)),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: widget.categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNote,
              child: _isLoading ? CircularProgressIndicator() : Text("Save Note"),
            ),
          ],
        ),
      ),
    );
  }
}