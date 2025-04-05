import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../widgets/bottom_navigation.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  final AnimalDetectionApi _api = AnimalDetectionApi();
  List<XFile> _pickedImages = [];
  Map<String, String> _animalLabels = {};
  bool _isProcessing = false;
  bool _analysisComplete = false;
  String _sessionId = '';
  Timer? _statusCheckTimer;
  String _debugLogs = '';

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _logDebug(String message) {
    print("DEBUG: $message");
    setState(() {
      _debugLogs += "$message\n";
    });
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.storage,
    ].request();

    if (statuses[Permission.photos]!.isPermanentlyDenied) {
      _logDebug("Photos permission permanently denied");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo permission is permanently denied. Please enable it from app settings.'),
          duration: Duration(seconds: 5),
        ),
      );
      openAppSettings();
    }
  }

  Future<void> _pickImages() async {
    await _requestPermissions();

    try {
      _logDebug("Opening image picker");
      final List<XFile> images = await _picker.pickMultiImage();
      _logDebug("Picked ${images.length} images");

      if (images.isNotEmpty) {
        setState(() {
          _pickedImages = images;
          _animalLabels = {};
          _analysisComplete = false;
          _sessionId = '';
        });

        if (_statusCheckTimer != null) {
          _statusCheckTimer!.cancel();
          _statusCheckTimer = null;
        }
      }
    } catch (e) {
      _logDebug("Error picking images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _processImages() async {
    if (_pickedImages.isEmpty) {
      _logDebug("No images selected");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select images first')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _analysisComplete = false;
    });

    try {
      _logDebug("Sending ${_pickedImages.length} images to API");

      // Convert XFile to File
      List<File> files = _pickedImages.map((xFile) => File(xFile.path)).toList();

      // Send images to API
      final response = await _api.startDetection(files);
      _logDebug("API response: $response");

      if (response.containsKey('session_id')) {
        _sessionId = response['session_id'];
        _logDebug("Got session ID: $_sessionId");

        // Start polling for results
        _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          _checkDetectionStatus();
        });
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      _logDebug("Error processing images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process images: $e')),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _checkDetectionStatus() async {
    if (_sessionId.isEmpty) return;

    try {
      _logDebug("Checking status for session: $_sessionId");
      final statusResponse = await _api.checkStatus(_sessionId);

      if (statusResponse['status'] == 'complete') {
        _logDebug("Processing complete, parsing results");
        _statusCheckTimer?.cancel();
        _statusCheckTimer = null;

        // Parse results
        Map<String, String> labels = {};
        for (var result in statusResponse['results']) {
          labels[result['filename']] = result['animal'];
        }

        setState(() {
          _animalLabels = labels;
          _analysisComplete = true;
          _isProcessing = false;
        });

        _logDebug("Results parsed: ${labels.length} labels");
      } else {
        _logDebug("Still processing...");
      }
    } catch (e) {
      _logDebug("Error checking status: $e");
    }
  }

  String _getAnimalLabel(String imagePath) {
    // Get just the filename part, regardless of path separators
    final fileName = imagePath.split('/').last.split('\\').last;

    // Don't log during build process
    // _logDebug("Looking for label for image: $fileName"); // Remove this line

    // Try to find an exact filename match
    if (_animalLabels.containsKey(fileName)) {
      return _animalLabels[fileName]!;
    }

    // If no exact match, try case-insensitive comparison
    for (var key in _animalLabels.keys) {
      if (key.toLowerCase() == fileName.toLowerCase()) {
        return _animalLabels[key]!;
      }
    }

    // If still no match, don't log during build
    // _logDebug("No match found for $fileName. Available keys: ${_animalLabels.keys.join(', ')}"); // Remove this line
    return 'Not analyzed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImages,
            tooltip: 'Pick Images',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Debug Logs'),
                  content: SingleChildScrollView(
                    child: SelectableText(_debugLogs),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _debugLogs = '';
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Show Debug Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _pickedImages.isEmpty
                ? Center(
              child: Text(
                'No images selected',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: _pickedImages.length,
              itemBuilder: (context, index) {
                final imagePath = _pickedImages[index].path;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                            ),
                            if (_analysisComplete)
                              Positioned(
                                right: 0,
                                left: 0,
                                bottom: 0,
                                child: Container(
                                  color: Colors.black54,
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: Text(
                                    _getAnimalLabel(imagePath),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Image ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _pickedImages.isEmpty || _isProcessing ? null : _processImages,
                child: _isProcessing
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('Processing...'),
                  ],
                )
                    : const Text('Start Analysis'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImages,
        tooltip: 'Pick Images',
        child: const Icon(Icons.add_photo_alternate),
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 4), // Add this line
    );
  }
}