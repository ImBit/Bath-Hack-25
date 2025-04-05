import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  String? _usernameError; 
  String _username = "";
  String? _passwordError;
  String _password = "";

  void _validateUsername() {
    setState(() {
      if (_username.isEmpty) {
        _usernameError = "Username cannot be empty";
      } else {
        _usernameError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      if (_password.isEmpty) {
        _passwordError = "Password cannot be empty";
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
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"), 
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Account Login",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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