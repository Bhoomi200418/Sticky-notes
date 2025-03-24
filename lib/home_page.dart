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
    displayedNotes = List.from(notes); 
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
  setState(() {
    isSortedByDate = !isSortedByDate;
    notes.sort((a, b) {
      DateTime dateA = a['date'] is String ? DateTime.parse(a['date']) : a['date'];
      DateTime dateB = b['date'] is String ? DateTime.parse(b['date']) : b['date'];
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
    final token = prefs.getString('token'); // Get token from storage

    if (token == null) {
      print("No token found. User not logged in.");
      return;
    }

    try {
      var response = await http.post(
        Uri.parse(
            'http://localhost:5000/api/user/logout'), // Replace with actual IP
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token" // Send token in header
        },
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("Logout successful");

        await prefs.remove('email');
        await prefs.remove('token');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout successful")),
        );

        Navigator.pushReplacementNamed(context, '/login');
      } else {
        print("Logout failed: ${response.body}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed. Try again.")),
        );
      }
    } catch (e) {
      print("Error during logout: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error. Please try again.")),
      );
    }
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
      String query = searchController.text.toLowerCase();

      if (query.isEmpty) {
        displayedNotes = List.from(notes); // Show all notes if search is empty
      } else {
        displayedNotes = notes.where((note) {
          return note['title']!.toLowerCase().contains(query) ||
                 note['content']!.toLowerCase().contains(query);
        }).toList();
      }
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
        displayedNotes = List.from(notes); 
      }
    });
  }

  // void _selectAllNotes() {
  //   setState(() {
  //     for (int i = 0; i < selectedNotes.length; i++) {
  //       selectedNotes[i] = true;
  //     }
  //   });
  // }

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
            Container(
              margin: EdgeInsets.all(8.0),
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 2.0)],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search Notes...",
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        searchController.clear();
                        showSearchBar = false;
                        displayedNotes = List.from(notes); 
                      });
                      _searchNotes(); 
                    },
                  ),
                ),
                onChanged: (value) {
                  _searchNotes();
                },
              ),
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
                icon: Icon(Icons.sort,
                    color: Colors.white), // Check icon color & visibility
                label: Text(isSortedByDate ? "Newest First" : "Oldest First"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 82, 164, 231),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              )
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
