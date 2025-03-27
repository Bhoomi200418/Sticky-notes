import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  OtpVerificationPage({required this.email});

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    String otp = otpControllers
        .map((controller) => controller.text)
        .join(); // Get OTP from all fields

    if (otp.isEmpty || otp.length < 6) {
      _showMessage("Please enter a valid 6-digit OTP.");
      return;
    }

    print("🔍 Entered OTP: $otp"); // Debugging

    final url = Uri.parse('http://localhost:5000/api/user/verify-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': widget.email, 'otp': otp}),
    );

    final responseData = jsonDecode(response.body);

    if (!mounted) return;

    if (response.statusCode == 200 && responseData['email'] != null) {
      String verifiedEmail = responseData['email'];
      _showMessage("OTP verified successfully!", isSuccess: true);

      Navigator.pushReplacementNamed(
        context,
        "/verify",
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
        backgroundColor: isSuccess ? Colors.green : Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Please enter the OTP sent to your email.',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 25),
                Form(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 50,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: 2,
                            color: [
                              Color(0xFFFD297B),
                              Color(0xFFFF655B),
                              Color(0xFFFF5864),
                            ][index % 3],
                          ),
                        ),
                        child: TextField(
                          controller: otpControllers[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              FocusScope.of(context).nextFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _verifyOTP,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFD297B),
                          Color(0xFFFF655B),
                          Color(0xFFFF5864),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
