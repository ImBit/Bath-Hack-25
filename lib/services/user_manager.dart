import 'package:flutter/cupertino.dart';
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
  static UserObject? _currentUser;

  // Static getter for the current user (NEW)
  static UserObject? get getCurrentUser => _currentUser;

  // Check if a user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Static method to check if user is logged in (NEW)
  static bool get isUserLoggedIn => _currentUser != null;

  // Set the current user and notify listeners
  static void setCurrentUser(UserObject user) {
    _currentUser = user;
    // notifyListeners();
  }

  // Log out the current user
  static void logout() {
    _currentUser = null;
    // notifyListeners();
  }

  // Get user ID or default value
  static String getUserId() {
    return _currentUser?.id ?? "PLACEHOLDER";
  }

  // Get user's display name
  static String getUserDisplayName() {
    return _currentUser?.username ?? "Guest";
  }

  static ImageProvider getActiveUserProfilePicture() {
    if (_currentUser == null) {
      return const AssetImage('assets/images/default_profile.png');
    }

    return _currentUser!.getProfilePictureImage();
  }

  // Get current date and time in UTC with specified format
  static String getCurrentUtcDateTimeFormatted() {
    final now = DateTime.now().toUtc();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }
}