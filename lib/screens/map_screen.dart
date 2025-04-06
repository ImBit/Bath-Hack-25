import 'package:animal_conservation/database/database_management.dart';
import 'package:animal_conservation/services/user_manager.dart';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
                        child: Image.asset('assets/Marker.png'),
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