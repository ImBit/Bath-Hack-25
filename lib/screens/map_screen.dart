import 'package:animal_conservation/database/database_management.dart';
import 'package:animal_conservation/database/objects/photo_object.dart';
import 'package:animal_conservation/services/user_manager.dart';
import 'package:flutter/material.dart';
import '../database/objects/user_object.dart';
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
  List<PhotoObject> allPhotos = [];
  List<PhotoObject> displayedPhotos = [];
  List<String> availableAnimals = [];
  bool isLoading = true;
  int? selectedMarkerIndex;
  bool viewAllPhotos = false; // For admin toggle between all photos and personal photos
  String? selectedAnimalFilter;

  // Date range values
  RangeValues _dateRangeValues = const RangeValues(0.0, 1.0);
  DateTime? oldestPhotoDate;
  DateTime? newestPhotoDate;
  bool _filterExpanded = false; // Track if filter panel is expanded

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Load user's photos first
      var photos = await FirestoreService.getPhotosByUser(UserManager.getUserId());
      userPhotos = photos.where((photo) => photo.getLatLng() != null).toList();
      displayedPhotos = List.from(userPhotos);

      // If user is staff, also load all photos but don't display them yet
      if (UserManager.getCurrentUser?.isUserStaff() == true) {
        allPhotos = await FirestoreService.getAllPhotos();
        allPhotos = allPhotos.where((photo) => photo.getLatLng() != null).toList();
      }

      // Get all available animals for filtering (for all users)
      Set<String> animalSet = {};
      List<PhotoObject> photosToProcess = UserManager.getCurrentUser?.isUserStaff() == true ?
      allPhotos : userPhotos;

      for (var photo in photosToProcess) {
        if (photo.animalClassification != null) {
          final animalInfo = await FirestoreService.getAnimalById(photo.animalClassification!);
          if (animalInfo != null && animalInfo.name != null) {
            animalSet.add(animalInfo.name!);
          }
        }
      }

      availableAnimals = animalSet.toList();
      availableAnimals.sort();

      // Find oldest and newest photo dates for timeline slider
      if (photosToProcess.isNotEmpty) {
        photosToProcess.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        oldestPhotoDate = photosToProcess.first.timestamp;
        newestPhotoDate = photosToProcess.last.timestamp;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading photos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _applyFilters() async {
    List<PhotoObject> sourcePhotos;
    if (UserManager.getCurrentUser?.isUserStaff() == true && viewAllPhotos) {
      sourcePhotos = List.from(allPhotos);
    } else {
      sourcePhotos = List.from(userPhotos);
    }

    List<PhotoObject> filteredPhotos = List.from(sourcePhotos);

    if (selectedAnimalFilter != null && selectedAnimalFilter!.isNotEmpty) {
      List<PhotoObject> tempFilteredPhotos = [];

      for (var photo in filteredPhotos) {
        if (photo.animalClassification != null) {
          final animalInfo = await FirestoreService.getAnimalById(photo.animalClassification!);
          if (animalInfo != null && animalInfo.name == selectedAnimalFilter) {
            tempFilteredPhotos.add(photo);
          }
        }
      }

      filteredPhotos = tempFilteredPhotos;
    }

    if (oldestPhotoDate != null && newestPhotoDate != null) {
      final totalDurationMs = newestPhotoDate!.difference(oldestPhotoDate!).inMilliseconds;

      final startDateMs = oldestPhotoDate!.millisecondsSinceEpoch +
          (totalDurationMs * _dateRangeValues.start).round();
      final endDateMs = oldestPhotoDate!.millisecondsSinceEpoch +
          (totalDurationMs * _dateRangeValues.end).round();

      final startDate = DateTime.fromMillisecondsSinceEpoch(startDateMs);
      final endDate = DateTime.fromMillisecondsSinceEpoch(endDateMs);

      filteredPhotos = filteredPhotos.where((photo) =>
      photo.timestamp.isAfter(startDate) &&
          photo.timestamp.isBefore(endDate)
      ).toList();
    }

    setState(() {
      displayedPhotos = filteredPhotos;
    });
  }

  // Toggle between all photos and personal photos (for staff only)
  void _toggleViewAll() {
    setState(() {
      viewAllPhotos = !viewAllPhotos;
    });

    _applyFilters();
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
    // Same as before
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
                  if (viewAllPhotos && photo.userId != null)
                    FutureBuilder<UserObject?>(
                        future: FirestoreService.getUserById(photo.userId!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Text('Submitted by: ${snapshot.data!.username}');
                          }
                          return const SizedBox();
                        }
                    ),
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
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Filter button for all users
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _filterExpanded ? Colors.amber : Colors.white,
            ),
            tooltip: _filterExpanded ? 'Hide Filters' : 'Show Filters',
            onPressed: () {
              setState(() {
                _filterExpanded = !_filterExpanded;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter controls section - available to all users
          if (_filterExpanded) _buildFilterControls(),

          // Map view
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
              options: MapOptions(
                initialCenter: displayedPhotos.isNotEmpty && displayedPhotos.first.getLatLng() != null
                    ? displayedPhotos.first.getLatLng()!
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
                  markers: List.generate(displayedPhotos.length, (index) {
                    final photo = displayedPhotos[index];
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
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 0),
    );
  }

  // Build the filter controls section with dropdown, range slider, and admin toggle
  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey.shade200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filter icon and animal dropdown
          Row(
            children: [
              const Icon(Icons.filter_list, size: 16.0, color: Colors.blue),
              const SizedBox(width: 4.0),
              Text(
                'Filter Controls',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              // Admin toggle for all/personal photos
              if (UserManager.getCurrentUser?.isUserStaff() == true)
                Row(
                  children: [
                    const Text('View All Photos'),
                    Switch(
                      value: viewAllPhotos,
                      onChanged: (value) {
                        _toggleViewAll();
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
            ],
          ),

          // Animal filter dropdown
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButton<String>(
              value: selectedAnimalFilter,
              hint: const Text('Filter by animal'),
              isDense: true,
              isExpanded: true,
              icon: const Icon(Icons.pets),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('All animals'),
                ),
                ...availableAnimals.map((animal) => DropdownMenuItem<String>(
                  value: animal,
                  child: Text(animal),
                )).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAnimalFilter = value;
                });
                _applyFilters();
              },
            ),
          ),

          // Date range labels
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date Range:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(_getDateRangeLabel()),
              ],
            ),
          ),

          // Date range slider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: RangeSlider(
              values: _dateRangeValues,
              min: 0.0,
              max: 1.0,
              divisions: 50,
              labels: RangeLabels(
                _getDateLabel(_dateRangeValues.start),
                _getDateLabel(_dateRangeValues.end),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _dateRangeValues = values;
                });
              },
              onChangeEnd: (RangeValues values) {
                _applyFilters();
              },
            ),
          ),

          // Date range markers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  oldestPhotoDate != null
                      ? _formatDate(oldestPhotoDate!)
                      : 'Oldest',
                  style: const TextStyle(fontSize: 12.0),
                ),
                Text(
                  newestPhotoDate != null
                      ? _formatDate(newestPhotoDate!)
                      : 'Newest',
                  style: const TextStyle(fontSize: 12.0),
                ),
              ],
            ),
          ),

          // Count of displayed photos
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${displayedPhotos.length} photos displayed',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Format date to human-readable string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get human-readable label for the current date range
  String _getDateRangeLabel() {
    if (oldestPhotoDate == null || newestPhotoDate == null) return '';

    final startDate = _getDateFromValue(_dateRangeValues.start);
    final endDate = _getDateFromValue(_dateRangeValues.end);

    return '${_formatDate(startDate)} to ${_formatDate(endDate)}';
  }

  // Get a specific date label for a slider position
  String _getDateLabel(double value) {
    if (oldestPhotoDate == null || newestPhotoDate == null) return '';
    return _formatDate(_getDateFromValue(value));
  }

  // Convert a slider value (0-1) to a specific date
  DateTime _getDateFromValue(double value) {
    final totalDurationMs = newestPhotoDate!.difference(oldestPhotoDate!).inMilliseconds;
    final dateMs = oldestPhotoDate!.millisecondsSinceEpoch +
        (totalDurationMs * value).round();
    return DateTime.fromMillisecondsSinceEpoch(dateMs);
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