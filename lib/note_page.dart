import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotePage extends StatefulWidget {
  final List<String> categories;
  final Map<String, dynamic>? existingNote;

  NotePage({required this.categories, this.existingNote});

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final List<String> categories = [
    "All",
    "Work",
    "Personal",
    "Wishlist",
    "Birthday"
  ];

  // String? userId;
  String? token;
  Color _selectedColor = Colors.white;
  bool _isLoading = false;
  String selectedCategory = "Work";
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    _loadUserData(); // ✅ Load userId and token when page opens

    if (widget.existingNote != null) {
      titleController.text = widget.existingNote!['title'];
      contentController.text = widget.existingNote!['text'];
      selectedCategory = widget.existingNote!['category'];
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? ''; // ✅ Prevents null token
    });
    print("Loaded Token: $token");

    if (token!.isNotEmpty) {
      _fetchNotes(); // ✅ Only fetch if token exists
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

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String apiUrl = "http://localhost:5000/api/note/all";

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer $token",
        },
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      print("📩 Fetched Notes (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200 && responseData['notes'] != null) {
        if (responseData['notes'] is List) {
          setState(() {
            notes = List<Map<String, dynamic>>.from(responseData['notes']);
          });
        } else {
          _showErrorDialog(context, "Invalid data received.");
        }
      } else {
        _showErrorDialog(context, "Failed to fetch notes.");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      "content": contentController.text.trim().isEmpty
          ? "No content"
          : contentController.text.trim(),
      "category": selectedCategory ?? "Uncategorized",
    };

    try {
      // ✅ Use proper API URL for mobile devices
      final String apiUrl =
          "http://localhost:5000/api/note/create"; // Android Emulator
      // For a real device, use your local IP instead of localhost

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
      _showErrorDialog(context, "Something went wrong. Please try again.");
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
            color: Colors.white,
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
                    await _createNote(context);
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










// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class NotePage extends StatefulWidget {
//   final List<String> categories;
//   final Map<String, dynamic>? existingNote;

//   NotePage({required this.categories, this.existingNote});

//   @override
//   _NotePageState createState() => _NotePageState();
// }

// class _NotePageState extends State<NotePage> {
//   final TextEditingController titleController = TextEditingController();
//   final TextEditingController contentController = TextEditingController();
//   final TextEditingController searchController = TextEditingController();

//   final List<String> categories = [
//     "All",
//     "Work",
//     "Personal",
//     "Wishlist",
//     "Birthday"
//   ];

//   // String? userId;
//   String? token;
//   Color _selectedColor = Colors.white;
//   bool _isLoading = false;
//   String selectedCategory = "Work";
//   List<Map<String, dynamic>> notes = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData(); // ✅ Load userId and token when page opens

//     if (widget.existingNote != null) {
//       titleController.text = widget.existingNote!['title'];
//       contentController.text = widget.existingNote!['text'];
//       selectedCategory = widget.existingNote!['category'];
//     }
//   }

//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       token = prefs.getString('token') ?? ''; // ✅ Prevents null token
//     });
//     print("Loaded Token: $token");

//     if (token!.isNotEmpty) {
//       _fetchNotes(); // ✅ Only fetch if token exists
//     }
//   }

//   void _showErrorDialog(BuildContext context, String message) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text("Error"),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _fetchNotes() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final String apiUrl = "http://localhost:5000/api/note/all";

//       final response = await http.get(
//         Uri.parse(apiUrl),
//         headers: {
//           "Content-Type": "application/json",
//           // "Authorization": "Bearer $token",
//         },
//       );

//       final responseData = jsonDecode(utf8.decode(response.bodyBytes));
//       print("📩 Fetched Notes (${response.statusCode}): ${response.body}");

//       if (response.statusCode == 200 && responseData['notes'] != null) {
//         if (responseData['notes'] is List) {
//           setState(() {
//             notes = List<Map<String, dynamic>>.from(responseData['notes']);
//           });
//         } else {
//           _showErrorDialog(context, "Invalid data received.");
//         }
//       } else {
//         _showErrorDialog(context, "Failed to fetch notes.");
//       }
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _createNote(BuildContext context) async {
//     if (titleController.text.trim().isEmpty) {
//       _showErrorDialog(context, "Title cannot be empty.");
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     // ✅ Ensure no null values are sent
//     final Map<String, dynamic> requestBody = {
//       "title": titleController.text.trim(),
//       "content": contentController.text.trim().isEmpty
//           ? "No content"
//           : contentController.text.trim(),
//       "category": selectedCategory ?? "Uncategorized",
//     };

//     try {
//       // ✅ Use proper API URL for mobile devices
//       final String apiUrl =
//           "http://localhost:5000/api/note/create"; // Android Emulator
//       // For a real device, use your local IP instead of localhost

//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(requestBody),
//       );

//       // ✅ Decode response safely
//       final responseData = jsonDecode(
//           utf8.decode(response.bodyBytes)); // Handles special characters
//       print("📩 Response (${response.statusCode}): $responseData");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         Navigator.pop(context, responseData);
//       } else {
//         _showErrorDialog(
//             context,
//             responseData['message'] ??
//                 responseData['error'] ??
//                 "Failed to create note.");
//       }
//     } catch (error) {
//       print("❌ Error creating note: $error");
//       _showErrorDialog(context, "Something went wrong. Please try again.");
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Note",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: const Color.fromARGB(255, 82, 164, 231),
//         actions: [
//           IconButton(
//             icon: _isLoading
//                 ? CircularProgressIndicator(color: Colors.white)
//                 : Icon(Icons.save, color: Colors.white),
//             onPressed: _isLoading
//                 ? null
//                 : () async {
//                     await _createNote(context);
//                   },
//           ),
//         ],
//       ),
//       body: Container(
//         padding: const EdgeInsets.all(16.0),
//         color: const Color(0xFFF3F4F6),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: TextField(
//                   controller: titleController,
//                   decoration: InputDecoration(
//                     hintText: "Title",
//                     hintStyle: TextStyle(color: Colors.black),
//                     border: InputBorder.none,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 15),
//             Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: DropdownButtonFormField<String>(
//                   decoration: InputDecoration(
//                     labelText: "Category",
//                     labelStyle: TextStyle(color: Colors.black),
//                     border: InputBorder.none,
//                   ),
//                   value: selectedCategory,
//                   items: categories.map((String category) {
//                     return DropdownMenuItem<String>(
//                       value: category,
//                       child: Text(
//                         category,
//                         style: TextStyle(color: Colors.black),
//                       ),
//                     );
//                   }).toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       selectedCategory = value!;
//                     });
//                   },
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//             Expanded(
//               child: Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: TextField(
//                     controller: contentController,
//                     maxLines: null,
//                     keyboardType: TextInputType.multiline,
//                     decoration: InputDecoration(
//                       hintText: "Write your note here...",
//                       hintStyle: TextStyle(color: Colors.black),
//                       border: InputBorder.none,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
