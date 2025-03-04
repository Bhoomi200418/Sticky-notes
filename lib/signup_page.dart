import 'package:flutter/material.dart';
import 'home_page.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Enter a valid email (e.g., example@gmail.com)';
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

  void _signup(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
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
                  Text('SIGN UP',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.blueGrey),
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
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
                    onPressed: () => _signup(context),
                    child: Text('SIGN UP'),
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
