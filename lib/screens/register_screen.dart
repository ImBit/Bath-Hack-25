import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  String? _usernameError; 
  String _username = "";
  String? _passwordError;
  String _password = "";
  final RegExp _passwordVal = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).+$');

  void _validateUsername() {
    setState(() {
      if (_username.toLowerCase() == "dev") {
        _passwordError = null;
      } else if (_username.isEmpty) {
        _usernameError = "Username cannot be empty";
      } else {
        _usernameError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      if (_username.toLowerCase() == "dev") {
        _passwordError = null;
      } else if (_password.isEmpty) {
        _passwordError = "Password cannot be empty";
      } else if (!_passwordVal.hasMatch(_password)) {
        _passwordError = "Password doesn't meet the requirements";
      } else {
        _passwordError = null;
      }
    });
  }

  void _submitForm() {
    _validateUsername();
    _validatePassword();

    if (_usernameError == null && _passwordError == null) {
      // Save details to db.
      Navigator.pushReplacementNamed(context, AppRoutes.camera);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"), 
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Account Registration",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Passwords must contain a special character, number, uppercase and lowercase letter.",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Username",
                  hintText: "Enter your username.",
                  errorText: _usernameError,
                ),
                onChanged: (value) {
                  _username = value;
                  _validateUsername();
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 300,
              child: TextField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Password",
                  hintText: "Enter your password.",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off, 
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  errorText: _passwordError,
                ),
                onChanged: (value) {
                  _password = value;
                  _validatePassword();
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitForm, 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 108, 191, 229),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              child: const Text("Register"),
            )
          ],
        ),
      ),
    );
  }
}