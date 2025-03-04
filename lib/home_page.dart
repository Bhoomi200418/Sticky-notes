// import 'package:flutter/material.dart';
import 'dart:math'; // For random colors
import 'package:table_calendar/table_calendar.dart';

import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:table_calendar/table_calendar.dart';
import 'dart:math';
import 'note_page.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<String> categories = ["All", "Work", "Personal", "Wishlist", "Birthday"];
  String selectedCategory = "All";
  List<Map<String, dynamic>> notes = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToNotePage() async {
    final newNote = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotePage(categories: categories)),
    );

    if (newNote != null) {
      setState(() {
        notes.add(newNote);
      });
    }
  }

  Widget _buildTasksScreen() {
    List<Map<String, dynamic>> filteredNotes = selectedCategory == "All"
        ? notes
        : notes.where((note) => note['category'] == selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map((category) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: selectedCategory == category,
                          onSelected: (selected) {
                            _onCategorySelected(category);
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: filteredNotes.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Click here to create your first task.",
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: filteredNotes[index]['color'],
                        child: ListTile(
                          title: GestureDetector(
                            onTap: () async {
                              final updatedNote = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotePage(
                                    categories: categories,
                                    existingNote: filteredNotes[index],
                                  ),
                                ),
                              );
                              if (updatedNote != null) {
                                setState(() {
                                  int noteIndex = notes.indexOf(filteredNotes[index]);
                                  notes[noteIndex] = updatedNote;
                                });
                              }
                            },
                            child: Text(filteredNotes[index]['title']),
                          ),
                          subtitle: Text("Category: ${filteredNotes[index]['category']}"),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                notes.remove(filteredNotes[index]);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMineScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 100, color: Colors.purple),
          SizedBox(height: 10),
          Text("User Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("user@example.com", style: TextStyle(fontSize: 14, color: Colors.grey)),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarScreen() {
  return Column(
    children: [
      TableCalendar(
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sticky Notes"),
        backgroundColor: const Color.fromARGB(255, 212, 173, 245),
      ),
      body: _selectedIndex == 0
          ? _buildTasksScreen()
          : _selectedIndex == 1
              ? _buildCalendarScreen()
              : _buildMineScreen(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _navigateToNotePage,
              child: Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Calendar"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Mine"),
        ],
      ),
    );
  }
}


class NotePage extends StatelessWidget {
  final List<String> categories;
  final Map<String, dynamic>? existingNote;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  String? selectedCategory;

  NotePage({required this.categories, this.existingNote}) {
    if (existingNote != null) {
      titleController.text = existingNote!['title'];
      contentController.text = existingNote!['text'];
      selectedCategory = existingNote!['category'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Note"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, {
                'title': titleController.text,
                'text': contentController.text,
                'category': selectedCategory ?? categories.first,
                'color': const Color.fromARGB(255, 238, 186, 234),
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(hintText: "Title"),
            ),
            Divider(),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Category"),
              value: selectedCategory,
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                selectedCategory = value;
              },
            ),
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
