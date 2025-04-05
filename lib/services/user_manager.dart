import 'package:flutter/foundation.dart';
import '../database/objects/user_object.dart';

class UserManager with ChangeNotifier {
  // Singleton pattern
  static final UserManager _instance = UserManager._internal();

  factory UserManager() {
    return _instance;
  }

  UserManager._internal();

  // The currently active user
  UserObject? _currentUser;

  // Getter for the current user
  UserObject? get currentUser => _currentUser;

  // Check if a user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Set the current user and notify listeners
  void setCurrentUser(UserObject user) {
    _currentUser = user;
    notifyListeners();
  }

  // Log out the current user
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Get user ID or default value
  String getUserId() {
    return _currentUser?.id ?? "PLACEHOLDER";
  }

  // Get user's display name
  String getUserDisplayName() {
    return _currentUser?.username ?? "Guest";
  }

  // Get current date and time in UTC with specified format
  String getCurrentUtcDateTimeFormatted() {
    final now = DateTime.now().toUtc();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }
}