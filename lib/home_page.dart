import 'dart:math'; // For random colors
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'note_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
   String? _email;
  final List<String> categories = [
    "All",
    "Work",
    "Personal",
    "Wishlist",
    "Birthday"
  ];
  String selectedCategory = "All";
  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> displayedNotes = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool showSearchBar = false;
  TextEditingController searchController = TextEditingController();
  List<bool> selectedNotes = [];
  bool isSelectAll = false; // Tracks "Select All" state
  bool isSortedByDate = false; // Tracks sorting state

  @override
  void initState() {
    super.initState();
    _loadEmail(); // Load email on startup
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('email') ?? 'No email found';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
      _filterNotes();
    });
  }

  void _filterNotes() {
    setState(() {
      displayedNotes = selectedCategory == "All"
          ? notes
          : notes
              .where((note) => note['category'] == selectedCategory)
              .toList();
    });
  }

  void _searchNotes() {
    setState(() {
      displayedNotes = notes
          .where((note) =>
              note['title']
                  .toLowerCase()
                  .contains(searchController.text.toLowerCase()) ||
              note['text']
                  .toLowerCase()
                  .contains(searchController.text.toLowerCase()))
          .toList();
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
        newNote['date'] = DateTime.now(); // Add current timestamp
        notes.add(newNote);
        selectedNotes.add(false);
        _filterNotes();
      });
    }
  }

  void _toggleSearchBar() {
    setState(() {
      showSearchBar = !showSearchBar;
      if (!showSearchBar) {
        searchController.clear();
        _filterNotes();
      }
    });
  }

  void _selectAllNotes() {
    setState(() {
      for (int i = 0; i < selectedNotes.length; i++) {
        selectedNotes[i] = true;
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      isSelectAll = !isSelectAll;
      for (int i = 0; i < selectedNotes.length; i++) {
        selectedNotes[i] = isSelectAll;
      }
    });
  }

  void _toggleSortByDate() {
    setState(() {
      isSortedByDate = !isSortedByDate;
      displayedNotes.sort((a, b) {
        return isSortedByDate
            ? (b['date'] as DateTime)
                .compareTo(a['date'] as DateTime) // Newest First
            : (a['date'] as DateTime)
                .compareTo(b['date'] as DateTime); // Oldest First
      });
    });
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
                          label: Text(
                            category,
                            style: TextStyle(
                              color: selectedCategory == category
                                  ? Colors.white // Text color when selected
                                  : Colors
                                      .black, // Text color when not selected
                            ),
                          ),
                          backgroundColor:
                              Colors.grey[300]!, // Default background color
                          selectedColor: const Color.fromARGB(255, 82, 164,
                              231), // Background color when selected
                          side: BorderSide(
                              color: const Color.fromRGBO(61, 184, 233, 1)), // Optional border
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (bool selected) {
                            _onCategorySelected(category);
                          },
                          selected: selectedCategory ==
                              category, // This is required in Flutter 3.27.1
                        ),
                      ))
                  .toList(),
            ),
          ),
          if (showSearchBar)
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search Notes...",
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _searchNotes();
                  },
                ),
              ),
              onChanged: (value) => _searchNotes(),
            ),
          SizedBox(height: 3.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _toggleSelectAll,
                icon: Icon(
                    isSelectAll
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: const Color.fromARGB(255, 255, 255, 255)),
                label: Text("Select All"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 82, 164, 231),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              SizedBox(width: 3),
              ElevatedButton.icon(
                onPressed: _toggleSortByDate,
                icon: Icon(Icons.sort, color: Colors.white),
                label: Text(isSortedByDate ? "Newest First" : "Oldest First"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 82, 164, 231),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(child: Text("Click here to create your first task"))
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      DateTime noteDate =
                          filteredNotes[index]['date'] ?? DateTime.now();
                      String formattedDate =
                          "${noteDate.day}/${noteDate.month}/${noteDate.year}";

                      return Card(
                        color: filteredNotes[index]['color'],
                        child: ListTile(
                          leading: Checkbox(
                            value: selectedNotes[index],
                            activeColor: const Color.fromARGB(
                                255, 255, 255, 255), // Change checkbox color
                            checkColor: Color.fromARGB(255, 82, 164, 231),
                            // Checkmark color inside the checkbox
                            onChanged: (value) {
                              setState(() {
                                selectedNotes[index] = value ?? false;
                              });
                            },
                          ),
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
                                  int noteIndex =
                                      notes.indexOf(filteredNotes[index]);
                                  notes[noteIndex] = updatedNote;
                                  _filterNotes();
                                });
                              }
                            },
                            child: Text(filteredNotes[index]['title']),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${filteredNotes[index]['category']}"),
                              Text(formattedDate,
                                  style: TextStyle(
                                      color:
                                          const Color.fromARGB(255, 0, 0, 0))),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                notes.remove(filteredNotes[index]);
                                _filterNotes();
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
          Icon(Icons.person,
              size: 100, color: const Color.fromARGB(255, 8, 104, 189)),
          SizedBox(height: 10),
          Text(_email ?? 'Loading...',
              style: TextStyle(
                  fontSize: 14, color: const Color.fromARGB(255, 0, 0, 0))),
          SizedBox(height: 19),
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 82, 164, 231),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
        title: Text("Sticky Notes "),
        backgroundColor: const Color.fromARGB(255, 19, 186, 236),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _toggleSearchBar,
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildTasksScreen()
          : _selectedIndex == 1
              ? _buildCalendarScreen()
              : _buildMineScreen(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _navigateToNotePage,
              backgroundColor:
                  const Color.fromARGB(255, 82, 164, 231), // Background color
              child: Icon(Icons.add,
                  color: Colors.white), // Icon color for contrast
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Tasks"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: "Calendar"),
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
        title: Text(
          "Note",
          style: TextStyle(
            color: Colors.white, // AppBar text color
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            const Color.fromARGB(255, 82, 164, 231), // Match homepage color
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: () {
              Navigator.pop(context, {
                'title': titleController.text,
                'text': contentController.text,
                'category': selectedCategory ?? categories.first,
                'color': const Color.fromARGB(255, 127, 192, 235),
              });
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: const Color(0xFFF3F4F6), // Light background for cleaner look
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
                    hintStyle:
                        TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
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
                    labelStyle:
                        TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
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
                    selectedCategory = value;
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
                      hintStyle:
                          TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
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
