import 'package:animal_conservation/database/database_management.dart';
import 'package:animal_conservation/database/objects/photo_object.dart';
import 'package:animal_conservation/services/user_manager.dart';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/rarity.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<PhotoObject> userPhotos = [];
  bool isLoading = true;
  int? selectedMarkerIndex;

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    try {
      var photos = await FirestoreService.getPhotosByUser(UserManager.getUserId());
      setState(() {
        userPhotos = photos
            .where((photo) => photo.getLatLng() != null)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading photos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Color> _getMarkerColor(PhotoObject photo) async {
    if (photo.animalClassification == null) return Colors.grey;

    try {
      final animalInfo = await FirestoreService.getAnimalById(photo.animalClassification!);
      if (animalInfo != null && animalInfo.rarity != null) {
        return Rarity.fromString(animalInfo.rarity).color;
      }
    } catch (e) {
      debugPrint('Error getting animal info: $e');
    }

    return Colors.grey;
  }

  void _showAnimalDetails(PhotoObject photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Animal Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      child: photo.encryptedImageData != null
                          ? Image(
                        image: photo.getImageProvider() ??
                            const AssetImage('assets/images/placeholder_animal.png'),
                        fit: BoxFit.contain,
                      )
                          : Image.asset(
                        'assets/images/placeholder_animal.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Date: ${photo.timestamp.toString().split('.')[0]}'),
                  if (photo.animalClassification != null)
                    FutureBuilder<AnimalObject?>(
                      future: FirestoreService.getAnimalById(photo.animalClassification!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('Loading animal information...');
                        }

                        if (snapshot.hasData && snapshot.data != null) {
                          final animalRarity = snapshot.data!.rarity ?? 'Unknown';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('Species: ${snapshot.data!.name}'),
                              Row(
                                children: [
                                  Text('Rarity: $animalRarity'),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Rarity.fromString(animalRarity).color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Description: ${snapshot.data!.description}'),
                              const SizedBox(height: 8),
                            ],
                          );
                        }

                        return const Text('No animal classification available');
                      },
                    ),
                  const SizedBox(height: 16),
                  if (photo.location != null && photo.location!.length >= 2)
                    Text('Location: ${photo.location![0]}, ${photo.location![1]}'),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: const Color.fromRGBO(255, 166, 0, 1),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: MapOptions(
          initialCenter: userPhotos.isNotEmpty && userPhotos.first.getLatLng() != null
              ? userPhotos.first.getLatLng()!
              : const LatLng(51.380007, -2.325986),
          initialZoom: 9.2,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            alignment: Alignment.topCenter,
            markers: List.generate(userPhotos.length, (index) {
              final photo = userPhotos[index];
              final location = photo.getLatLng()!;

              return Marker(
                point: location,
                width: 60,
                height: 60,
                rotate: false,
                child: FutureBuilder<Color>(
                    future: selectedMarkerIndex == index
                        ? _getMarkerColor(photo)
                        : Future.value(Colors.white),
                    builder: (context, snapshot) {
                      return FixedRotationMarker(
                        normalWidth: 60,
                        normalHeight: 60,
                        pressedWidth: 160,
                        pressedHeight: 160,
                        imagePath: 'assets/Marker.png',
                        markerColor: snapshot.data ?? Colors.white,
                        onPressed: () {
                          setState(() {
                            selectedMarkerIndex = index;
                          });
                          _showAnimalDetails(photo);
                        },
                      );
                    }
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 0),
    );
  }
}

class FixedRotationMarker extends StatefulWidget {
  final double normalWidth;
  final double normalHeight;
  final double pressedWidth;
  final double pressedHeight;
  final String imagePath;
  final Color markerColor;
  final Function? onPressed;

  const FixedRotationMarker({
    super.key,
    required this.normalWidth,
    required this.normalHeight,
    required this.pressedWidth,
    required this.pressedHeight,
    required this.imagePath,
    required this.markerColor,
    this.onPressed,
  });

  @override
  FixedRotationMarkerState createState() => FixedRotationMarkerState();
}

class FixedRotationMarkerState extends State<FixedRotationMarker> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
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
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(widget.markerColor, BlendMode.modulate),
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.contain,
            ),
          ),
        )
    );
  }
}