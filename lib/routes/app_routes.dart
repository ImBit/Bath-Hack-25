import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/animal_info_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String camera = '/camera';
  static const String gallery = '/gallery';
  static const String animalInfo = '/animal-info';
  static const String profile = '/profile';
  static const String login = "/login";
  static const String register = "/register";

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const JournalView(),
    camera: (context) => const CameraScreen(),
    gallery: (context) => const GalleryScreen(),
    animalInfo: (context) => const AnimalInfoScreen(),
    profile: (context) => const ProfileScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
  };
}