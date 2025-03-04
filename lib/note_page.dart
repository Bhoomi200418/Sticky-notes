import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!['title'];
      _selectedCategory = widget.existingNote!['category'];
      _selectedColor = widget.existingNote!['color'];
    }
  }

  void _saveNote() {
    Map<String, dynamic> note = {
      'title': _titleController.text,
      'category': _selectedCategory,
      'color': _selectedColor,
    };
    Navigator.pop(context, note);
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
