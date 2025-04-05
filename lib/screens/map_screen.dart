import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(45.3367881884556, 14.159452282322459), // Center the map over London
          initialZoom: 9.2,
        ),
        children: [
          TileLayer( // Bring your own tiles
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // For demonstration only
            userAgentPackageName: 'com.example.app', // Add your app identifier
          ),
          OverlayImageLayer(
            overlayImages: [
              OverlayImage( // Unrotated
                bounds: LatLngBounds(
                  const LatLng(45.3367881884556, 14.159452282322459),
                  const LatLng(45.264129635422826, 14.252585831779033),
                ),
                imageProvider: const NetworkImage("https://hard-drive.net/wp-content/uploads/2024/01/jb.jpg"),
              ),
            ],
          ),
        ]
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 0),
    );
  }
}