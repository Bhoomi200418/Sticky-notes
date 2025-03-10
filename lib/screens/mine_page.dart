import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MinePage extends StatefulWidget {
  @override
  _MinePageState createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? 'Unknown User';
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person,
                size: 100, color: const Color.fromARGB(255, 8, 104, 189)),
            SizedBox(height: 10),
            Text(userEmail,
                style: TextStyle(
                    fontSize: 14, color: const Color.fromARGB(255, 0, 0, 0))),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _logout,
              child: Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
