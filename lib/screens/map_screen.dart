import 'package:animal_conservation/database/database_management.dart';
import 'package:animal_conservation/services/user_manager.dart';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PressableMarker extends StatefulWidget {
  final double normalWidth;
  final double normalHeight; 
  final double pressedWidth;
  final double pressedHeight;
  final String imagePath;

  const PressableMarker({
    super.key, 
    required this.normalWidth,
    required this.normalHeight,
    required this.pressedWidth,
    required this.pressedHeight,
    required this.imagePath,
  });

  @override
  PressableMarkerState createState() => PressableMarkerState();
}

class PressableMarkerState extends State<PressableMarker> {
  bool _isPressed = false; 

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override 
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isPressed ? widget.pressedWidth : widget.normalWidth,
        height: _isPressed ? widget.pressedHeight : widget.normalHeight,
        child: Image.asset(
          widget.imagePath,
          fit: BoxFit.contain,
          )
      )
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> photoLocations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLocations();
  }

  Future<void> loadLocations() async {
    try {
      var photos = await FirestoreService.getPhotosByUser(UserManager.getUserId());
      setState(() {
        photoLocations = photos
            .map((photo) => photo.getLatLng())
            .where((latLng) => latLng != null)
            .cast<LatLng>()
            .toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: photoLocations.isNotEmpty
                    ? photoLocations.first
                    : const LatLng(51.380007, -2.325986), // Default center if no photos
                initialZoom: 9.2,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  alignment: Alignment.topCenter,
                  markers: [
                    ...photoLocations.map(
                      (location) => Marker(
                        point: location,
                        width: 60,
                        height: 60,
                        child: const PressableMarker(
                          normalWidth: 60,
                          normalHeight: 60,
                          pressedWidth: 160,
                          pressedHeight: 160,
                          imagePath: 'assets/Marker.png'
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 0),
    );
  }
}