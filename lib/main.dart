import 'package:flutter/material.dart';
import 'package:sticky_notes/home_page.dart';
import 'package:sticky_notes/login_page.dart';
import 'package:sticky_notes/verify_page.dart';
import 'package:sticky_notes/otp_verification.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: LoginPage(),
        routes: {
          '/homepage': (context) => HomePage(),
          '/verify': (context) => SignUpPage(),
          '/login': (context) => LoginPage()
        
        });
  }
}
