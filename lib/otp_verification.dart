import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sticky_notes/signup_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  OtpVerificationPage({required this.email});

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController otpController = TextEditingController();

  Future<void> _verifyOtp() async {
    final url = Uri.parse('http://localhost:5000/api/user/verify-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': widget.email, 'otp': otpController.text}),
    );

    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      String verifiedEmail =
          responseData['email']; // Extract email from response
      _showMessage("OTP verified successfully!", isSuccess: true);
      // Navigate to Signup page with email as argument
      Navigator.pushReplacementNamed(
        context,
        "/verifypage",
        arguments: {'email': verifiedEmail},
      );
    } else {
      _showMessage(responseData['message'] ?? "Invalid OTP. Try again.");
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : const Color.fromARGB(255, 0, 0, 0),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter OTP',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey)),
                SizedBox(height: 10),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter OTP',
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(244, 67, 54, 1),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _verifyOtp,
                  child: Text('Verify'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
