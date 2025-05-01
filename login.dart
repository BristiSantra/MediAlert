import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'choice.dart';




class NurseLoginPage extends StatefulWidget {
  @override
  _NurseLoginPageState createState() => _NurseLoginPageState();
}

class _NurseLoginPageState extends State<NurseLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  @override
  void initState() {
    super.initState();
  }


  Future<void> _login() async {
    final response = await http.post(
      Uri.parse('http://192.168.68.140:8000/nurse_login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      }),
    );

    print('Raw Response Body: ${response.body}');

    try {
      final responseData = json.decode(response.body);
      print('Response: $responseData');

      if (response.statusCode == 200) {
        // Setup notifications after successful login
        // await _setupPushNotifications();

        final nurseName = responseData['name'] ?? 'Nurse';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => WelcomePage(nurseName: nurseName)),
        );
      } else {
        setState(() {
          //_errorMessage =
          responseData['error'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      print('Error decoding response: $e');
      setState(() {
        //_errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.orange.shade50,
  //     body: Center(
  //       child: SingleChildScrollView(
  //         padding: const EdgeInsets.all(24.0),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.health_and_safety, size: 100, color: Colors.teal),
  //             SizedBox(height: 20),
  //             Text(
  //               'Smart Fall Detection and Saline Monitoring',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.teal.shade800,
  //               ),
  //             ),
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety, size: 100, color: Colors.teal),
              SizedBox(height: 10), // Reduced space
              Text(
                'MediAlert+',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
              SizedBox(height: 4), // Minimal space
              Text(
                'Smart Fall Detection & Saline Monitoring', // Tagline
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.teal.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Form(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter your email' : null,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? 'Enter your password' : null,
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding:
                        EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    // if (_errorMessage.isNotEmpty) ...[
                    //   SizedBox(height: 20),
                    //   Text(
                    //     _errorMessage,
                    //     style: TextStyle(color: Colors.red),
                    //   ),
                    // ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class WelcomePage extends StatelessWidget {
  final String nurseName;

  WelcomePage({required this.nurseName});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserChoicePage()),
      );
    });

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: Center(
        child: Text(
          'Welcome, $nurseName!',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
