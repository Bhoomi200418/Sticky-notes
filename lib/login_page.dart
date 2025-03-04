import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      var url = Uri.parse("http://localhost:3000/api/user/login");
      print("Sending request to: $url");
      try {
        var response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email, "password": password}),
        );

        print("Response status: \${response.statusCode}");
        print("Response body: \${response.body}");

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          print("Login Successful: \${data['message']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login Successful!")),
          );
          await Future.delayed(Duration(seconds: 1));
          Navigator.pushReplacementNamed(context, "/homepage");
        } else {
          var errorData = jsonDecode(response.body);
          String errorMessage = errorData['error'];

          if (errorMessage.contains("Email not registered")) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("This email is not registered. Please sign up first.")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Login Failed: $errorMessage")),
            );
          }
        }
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Something went wrong. Please try again!")),
        );
      }
    }
  }

  void _signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signIn();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (error) {
      print(error);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    String pattern = r'^[a-zA-Z0-9._%+-]+@gmail\.com$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Only Gmail accounts are allowed (e.g., example@gmail.com)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('WELCOME',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey)),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email, color: Colors.blueGrey),
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateEmail,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock, color: Colors.blueGrey),
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitForm,
                    child: Text('LOGIN'),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupPage()),
                      );
                    },
                    child: Text("Don't have an account? Sign Up",
                        style: TextStyle(color: Colors.blueGrey)),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _signInWithGoogle(context),
                    child: Text('Sign in with Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
