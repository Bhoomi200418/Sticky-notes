import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  String userId = "";
  String token = "your_jwt_token";
  bool showSearchBar = false;
  TextEditingController searchController = TextEditingController();
  List<bool> selectedNotes = [];
  bool isSelectAll = false;
  bool isSortedByDate = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    try {
      var response =
          await http.get(Uri.parse('http://localhost:5000/api/note/all'));

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> fetchedNotes =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        for (var note in fetchedNotes) {
          if (note['date'] != null && note['date'].toString().isNotEmpty) {
            note['date'] = DateTime.tryParse(note['date']) ?? DateTime.now();
          } else {
            note['date'] = DateTime.now(); // Assign a default date if null
          }
        }

        setState(() {
          notes = fetchedNotes;
          displayedNotes = List.from(notes);
          selectedNotes = List.filled(notes.length, false);
        });

        print("Fetched notes: ${notes.length}");
      } else {
        print("Error fetching notes: ${response.body}");
      }
    } catch (e) {
      print('Error fetching notes: $e');
    }
  }

//   Future<void> updateNote(String noteId, String title, String content) async {
//   final String apiUrl = 'http://localhost:5000/api/note/update/$noteId';

//   try {
//     final response = await http.put(
//       Uri.parse(apiUrl),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "title": title,
//         "content": content,
//       }),
//     );

//     if (response.statusCode == 200) {
//       print("Note updated successfully");
//     } else {
//       print("Failed to update note: ${response.body}");
//     }
//   } catch (e) {
//     print("Error: $e");
//   }
// }

  Future<void> _deleteNote(String id) async {
    try {
      var response = await http
          .delete(Uri.parse('http://localhost:5000/api/note/delete/$id'));
      if (response.statusCode == 200) {
        setState(() {
          notes.removeWhere((note) => note['_id'] == id);
          displayedNotes = List.from(notes);
        });
      }
    } catch (e) {
      print('Error deleting note: $e');
    }
  }

  void _toggleSortByDate() {
    if (displayedNotes.isEmpty) {
      print("No notes to sort.");
      return;
    }

    setState(() {
      isSortedByDate = !isSortedByDate;
      displayedNotes.sort((a, b) {
        DateTime dateA = a['date'] is DateTime ? a['date'] : DateTime.now();
        DateTime dateB = b['date'] is DateTime ? b['date'] : DateTime.now();
        return isSortedByDate ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
      });
    });
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('email') ?? 'No email found';
    });
  }

  void _changeColor(Color color) {
    setState(() {
      // _selectedColor = color;
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
      MaterialPageRoute(
        builder: (context) => NotePage(
          categories: categories,
        ),
      ),
    );

    if (newNote != null) {
      _fetchNotes();
      setState(() {
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
                              color: const Color.fromRGBO(
                                  61, 184, 233, 1)), // Optional border
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (bool selected) {
                            _onCategorySelected(category);
                          },
                          selected: selectedCategory == category,
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
                      DateTime noteDate = filteredNotes[index]['date'] is String
                          ? DateTime.parse(filteredNotes[index]['date'])
                          : filteredNotes[index]['date'];

                      String formattedDate =
                          "${noteDate.day}/${noteDate.month}/${noteDate.year}";

                      return Card(
                        color: filteredNotes[index]['color'],
                        child: ListTile(
                          leading: Checkbox(
                            value: selectedNotes[index],
                            activeColor:
                                const Color.fromARGB(255, 255, 255, 255),
                            checkColor: Color.fromARGB(255, 82, 164, 231),
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
                                _fetchNotes();
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
                            onPressed: () async {
                              String noteId = filteredNotes[index]
                                  ['_id']; // Get the note ID

                              await _deleteNote(
                                  noteId); // Call the delete function

                              setState(() {
                                notes.removeWhere(
                                    (note) => note['_id'] == noteId);
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
