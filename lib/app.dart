import 'package:animal_conservation/screens/camera_screen.dart';
import 'package:animal_conservation/screens/journal_screen.dart';
import 'package:animal_conservation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Animal Detection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const RegisterScreen(),
      routes: {
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.camera: (context) => const CameraScreen(),
      },
    );
  }
}