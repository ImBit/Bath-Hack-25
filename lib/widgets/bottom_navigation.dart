import 'package:animal_conservation/screens/map_screen.dart';
import 'package:animal_conservation/screens/camera_screen.dart';
import 'package:animal_conservation/screens/gallery_screen.dart';
import 'package:animal_conservation/screens/journal_screen.dart';
import 'package:animal_conservation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      backgroundColor: Color.fromRGBO(255, 166, 0, 1),
      onTap: (index) {
        if (index == currentIndex) return;

        final screens = [
          const MapScreen(),
          const JournalView(),
          const CameraScreen(),
          const ProfileScreen(),
          const ProfileScreen(),
        ];

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                screens[index],
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.map, color: Colors.black),
          label: 'Map',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.list_alt, color: Colors.black),
          label: 'Journal',
        ),
        BottomNavigationBarItem(
          icon: Container(
            decoration: const BoxDecoration(
              color: Colors
                  .blue, // You can use Theme.of(context).colorScheme.primary if you want
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
            ),
          ),
          label: 'Camera',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person, color: Colors.black),
          label: 'Profile',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings, color: Colors.black),
          label: 'Settings',
        ),
      ],
    );
  }
}