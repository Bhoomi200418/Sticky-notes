import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotePage extends StatefulWidget {
  final List<String> categories;
  final Map<String, dynamic>? existingNote;
  final bool isEditing;  
  final String? noteId;  

  NotePage({
    Key? key,
    required this.categories,
    this.existingNote,
    this.isEditing = false, // Default value added
    this.noteId,
  }) : super(key: key);

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();


  final List<String> categories = [
    "All",
    "Work",
    "Personal",
    "Wishlist",
    "Birthday"
  ];
  String? token;
 
  bool _isLoading = false;
  bool isEditing = true;
 String? existingNoteId;

  String selectedCategory = "All";
  List<Map<String, dynamic>> notes = [];

@override
void initState() {
  super.initState();
  _loadUserData(); 

  if (widget.existingNote != null) {
    titleController.text = widget.existingNote!['title'] ?? '';
    contentController.text = widget.existingNote!['content'] ?? ''; 
    selectedCategory = widget.existingNote!['category'] ?? 'Uncategorized';
  }
}

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? ''; 
    });
    print("Loaded Token: $token");

    if (token!.isNotEmpty) {
     
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
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
Future<void> _updateNote(String noteId, String title, String content, String category) async {
  print("Updating Note ID: $noteId");
  print("📌 Title: $title");
  print("📌 Content: $content");
  print("📌 Category: $category");

  try {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      print("❌ Error: No authentication token found.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unauthorized: Please log in again.")),
      );
      return;
    }

    var response = await http.put(
      Uri.parse('http://localhost:5000/api/note/update/$noteId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",  // 🔹 Added Authorization Header
      },
      body: jsonEncode({
        "title": title,
        "content": content,
        "category": category
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Note updated successfully");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Note updated successfully!")),
      );

      Navigator.pop(context, true);
    } else {
      print("❌ Failed to update note: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update note. ${jsonDecode(response.body)['error']}")),
      );
    }
  } catch (e) {
    print("❌ Error updating note: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("An error occurred. Please try again.")),
    );
  }
}


 Future<void> _createNote(BuildContext context) async {
    if (titleController.text.trim().isEmpty) {
      _showErrorDialog(context, "Title cannot be empty.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // ✅ Ensure no null values are sent
    final Map<String, dynamic> requestBody = {
      "title": titleController.text.trim(),
      "content": contentController.text.trim(),
          // ? "No content"
          // : contentController.text.trim(),
      "category": selectedCategory 
    };

    try {
      // ✅ Use proper API URL for mobile devices
      final String apiUrl =
          "http://localhost:5000/api/note/create"; 
     

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );

      // ✅ Decode response safely
      final responseData = jsonDecode(
          utf8.decode(response.bodyBytes)); // Handles special characters
      print("📩 Response (${response.statusCode}): $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, responseData);
      } else {
        _showErrorDialog(
            context,
            responseData['message'] ??
                responseData['error'] ??
                "Failed to create note.");
      }
    } catch (error) {
      print("❌ Error creating note: $error");
      _showErrorDialog(context, "Something went wrong. Please try again");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Note",
          style: TextStyle(
            color: const Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 82, 164, 231),
       actions: [
 IconButton(
  icon: _isLoading
      ? CircularProgressIndicator(color: Colors.white)
      : Icon(Icons.save, color: Colors.white),
  onPressed: _isLoading
      ? null
      : () async {
          setState(() => _isLoading = true);

          if (widget.existingNote != null) {
            // ✅ Call Update API if editing
            await _updateNote(
              widget.existingNote!['_id'],  
              titleController.text,
              contentController.text,
              selectedCategory
           
            );
          } else {
            // ✅ Call Create API if new note
            await _createNote(context);
          }

          setState(() => _isLoading = false);
        },
),


],

      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: const Color(0xFFF3F4F6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: "Title",
                    hintStyle: TextStyle(color: Colors.black),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Category",
                    labelStyle: TextStyle(color: Colors.black),
                    border: InputBorder.none,
                  ),
                  value: selectedCategory,
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: contentController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: "Write your note here...",
                      hintStyle: TextStyle(color: Colors.black),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
