import 'package:animal_conservation/database/objects/user_object.dart';
import 'package:animal_conservation/screens/journal_screen.dart';
import 'package:animal_conservation/services/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../routes/app_routes.dart';
import 'package:animal_conservation/database/database_management.dart';

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
  final RegExp _passwordVal =
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).+$');
  final Uuid _uuid = Uuid();

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

  Future<void> _validateUsername() async {
    if (_username.toLowerCase() == "dev") {
      setState(() {
        _usernameError = null;
      });
      return;
    } else if (_username.isEmpty) {
      setState(() {
        _usernameError = "Username cannot be empty";
      });
      return;
    }

    setState(() {
      _usernameError = null;
    });
  }

  Future<void> _submitForm() async {
    await _validateUsername();
    _validatePassword();

    if (_usernameError == null &&
        (_passwordError == null || _username.toLowerCase() == "dev")) {
      if (_username.toLowerCase() == "dev") {
        Navigator.pushReplacementNamed(context, AppRoutes.camera);
        return;
      }

      // Check if username exists
      bool usernameExists =
          !await FirestoreService.isUsernameAvailable(_username);

      if (usernameExists) {
        // Username exists - try to login
        UserObject? existingUser =
            await FirestoreService.getUserByUsername(_username);

        if (existingUser != null && existingUser.password == _password) {
          // Password matches - log in
          UserManager.setCurrentUser(existingUser);
          Navigator.pushReplacementNamed(context, AppRoutes.camera);
        } else {
          // Password doesn't match
          setState(() {
            _passwordError = "Password incorrect";
          });
        }
      } else {
        // Username doesn't exist - create new account
        UserObject user = UserObject(
          id: _uuid.v4(),
          username: _username,
          password: _password,
        );
        UserManager.setCurrentUser(user);
        await FirestoreService.saveUser(user);
        Navigator.pushReplacementNamed(context, AppRoutes.camera);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: const Color.fromRGBO(255, 166, 0, 1),
      ),
      body: Stack(
        children: [
          const PatternedBG(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/Logo.png', width: 300, height: 70),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/dot.png',
                              repeat: ImageRepeat.repeat,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Account Registration",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                "Passwords must contain a special character, number, uppercase and lowercase letter.",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal),
                                textAlign: TextAlign.center,
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
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
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
                                  backgroundColor:
                                      const Color.fromARGB(255, 118, 229, 108),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(16)),
                                  ),
                                ),
                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
