import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'screens/camera_screen.dart';
import 'screens/gallery_screen.dart';
// Import other screens as needed

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await Permission.storage.request();
  }

  runApp(const MyApp());
}