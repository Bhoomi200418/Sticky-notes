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
  

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!['title'];
      _selectedCategory = widget.existingNote!['category'];
      _selectedColor = widget.existingNote!['color'];
    }
  }

  // void _saveNote() {
  //   Map<String, dynamic> note = {
  //     'title': _titleController.text,
  //     'category': _selectedCategory,
  //     'color': _selectedColor,
  //   };
  //   Navigator.pop(context, note);
  // }

  Future<void> _saveNote() async {
    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> note = {
      'title': _titleController.text,
      'category': _selectedCategory,
      'color': _selectedColor.toString(),
      'userId': '123456', // Replace with actual user ID
    };
  
   try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(note),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Note Created: ${response.body}");
        Navigator.pop(context, note);
      } else {
        print("Error Creating Note: ${response.body}");
        _showErrorDialog("Failed to create note. Try again.");
      }
    } catch (error) {
      print("Error: $error");
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
            icon: Icon(Icons.check),
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
              child: Text("Save Note"),
            ),
          ],
        ),
      ),
    );
  }
}
