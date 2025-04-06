import 'dart:async';
import 'dart:io';
import 'package:animal_conservation/screens/journal_screen.dart';
import 'package:animal_conservation/services/image_encryptor.dart';
import 'package:animal_conservation/services/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/database_management.dart';
import '../database/objects/photo_object.dart';
import '../services/animalcreatorservice.dart';
import '../services/api_service.dart';
import '../services/location_manager.dart';
import '../utils/storage_manager.dart';
import '../widgets/bottom_navigation.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  final AnimalDetectionApi _api = AnimalDetectionApi();
  final StorageManager _storageManager = StorageManager();

  List<File> _appImages = [];
  Map<String, String> _animalLabels = {};
  bool _isProcessing = false;
  bool _analysisComplete = false;
  String _sessionId = '';
  Timer? _statusCheckTimer;
  String _debugLogs = '';
  bool _isLoading = true;
  bool _isImageChanged = false;

  @override
  void initState() {
    super.initState();
    // Load images from storage on startup
    _loadImagesFromStorage();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _logDebug(String message) {
    print("DEBUG: $message");
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _debugLogs += "$message\n";
        });
      }
    });
  }

  // Enhanced method to load images from storage with error handling
  Future<void> _loadImagesFromStorage() async {
    setState(() {
      _isLoading = true;
      _isImageChanged = false;
    });

    try {
      _logDebug("Loading images from StorageManager");
      final images = await _storageManager.getAllImages();

      setState(() {
        _appImages = images;
        _isLoading = false;
      });

      _logDebug("Successfully loaded ${images.length} images from StorageManager");

      // If we have images loaded but no labels, reset analysis state
      if (images.isNotEmpty && _animalLabels.isEmpty) {
        setState(() {
          _analysisComplete = false;
        });
      }
    } catch (e) {
      _logDebug("Error loading images from StorageManager: $e");
      setState(() {
        _isLoading = false;
        _appImages = []; // Reset to empty list on error
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load images from storage: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadImagesFromStorage,
          ),
        ),
      );
    }
  }

  Future<void> _requestPermissions(PermissionType type) async {
    // List<Permission> permissions = [];
    //
    // switch (type) {
    //   case PermissionType.camera:
    //     permissions = [Permission.camera];
    //     break;
    //   case PermissionType.gallery:
    //     permissions = [Permission.photos, Permission.storage];
    //     break;
    // }
    //
    // Map<Permission, PermissionStatus> statuses = await permissions.request();
    //
    // for (var permission in permissions) {
    //   if (statuses[permission]!.isPermanentlyDenied) {
    //     _logDebug("${permission.toString()} permission permanently denied");
    //     if (!mounted) return;
    //
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('${permission.toString()} permission is permanently denied. Please enable it from app settings.'),
    //         duration: const Duration(seconds: 5),
    //         action: SnackBarAction(
    //           label: 'Settings',
    //           onPressed: () => openAppSettings(),
    //         ),
    //       ),
    //     );
    //   }
    // }
  }

  // Enhanced camera capture with explicit storage manager usage
  Future<void> _takePhoto() async {
    await _requestPermissions(PermissionType.camera);

    try {
      _logDebug("Opening camera");
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        _logDebug("Photo captured: ${image.path}");

        // Save to StorageManager
        final savedFile = await _storageManager.saveImage(File(image.path));
        _logDebug("Image saved to StorageManager at: ${savedFile.path}");

        setState(() {
          _appImages.add(savedFile);
          _isImageChanged = true;
          // Reset analysis state when new image is added
          _analysisComplete = false;
          _animalLabels = {};
        });

        // Show success notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo saved to app storage')),
          );
        }
      }
    } catch (e) {
      _logDebug("Error taking photo: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  // Enhanced gallery import with explicit storage manager usage
  Future<void> _pickImagesFromGallery() async {
    await _requestPermissions(PermissionType.gallery);

    try {
      _logDebug("Opening image picker");
      final List<XFile> images = await _picker.pickMultiImage();
      _logDebug("Picked ${images.length} images from gallery");

      if (images.isNotEmpty) {
        List<File> savedFiles = [];

        // Show progress indicator for multiple images
        if (mounted && images.length > 3) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text("Importing ${images.length} images to storage..."),
                ],
              ),
            ),
          );
        }

        // Save all images to StorageManager
        for (var image in images) {
          _logDebug("Saving image to StorageManager: ${image.path}");
          final savedFile = await _storageManager.saveImage(File(image.path));
          savedFiles.add(savedFile);
        }

        // Dismiss dialog if showing
        if (mounted && images.length > 3) {
          Navigator.of(context).pop();
        }

        setState(() {
          _appImages.addAll(savedFiles);
          _isImageChanged = true;
          // Reset analysis state when new images are added
          _analysisComplete = false;
          _animalLabels = {};
          _sessionId = '';
        });

        if (_statusCheckTimer != null) {
          _statusCheckTimer!.cancel();
          _statusCheckTimer = null;
        }

        _logDebug("Added ${savedFiles.length} images to StorageManager");

        // Show success notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${savedFiles.length} images imported to app storage')),
          );
        }
      }
    } catch (e) {
      _logDebug("Error picking images from gallery: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing images: $e')),
      );
    }
  }

  // Clear all images from storage manager
  Future<void> _clearAllImages() async {
    try {
      _logDebug("Clearing all images from StorageManager");

      // Show confirmation dialog
      bool confirmed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear All Images?'),
          content: const Text('Are you sure you want to delete all images? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete All'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirmed) return;

      // Clear all images from storage
      await _storageManager.clearAllImages();

      setState(() {
        _appImages = [];
        _animalLabels = {};
        _analysisComplete = false;
        _isImageChanged = false;
      });

      _logDebug("All images cleared from StorageManager");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All images deleted')),
      );
    } catch (e) {
      _logDebug("Error clearing images: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear images: $e')),
      );
    }
  }

  Future<void> _processImages() async {
    if (_appImages.isEmpty) {
      _logDebug("No images available for analysis");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images available for analysis')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _analysisComplete = false;
    });

    try {
      _logDebug("Sending ${_appImages.length} images to API for analysis");

      // Send images to API
      final response = await _api.startDetection(_appImages);
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
      if (!mounted) return;

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

        // Now save the analyzed images to database
        await _saveAnalyzedImagesToDB();
      } else {
        _logDebug("Still processing...");
      }
    } catch (e) {
      _logDebug("Error checking status: $e");
    }
  }

  String _getAnimalLabel(File imageFile) {
    // Get just the filename part
    final fileName = path.basename(imageFile.path);

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

    return 'Not analyzed';
  }

  // Enhanced image deletion with improved error handling
  Future<void> _deleteImage(File imageFile) async {
    try {
      _logDebug("Deleting image from StorageManager: ${imageFile.path}");
      await _storageManager.deleteImage(imageFile);

      setState(() {
        _appImages.remove(imageFile);
        _isImageChanged = true;
      });

      _logDebug("Image deleted successfully from StorageManager");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted from app storage')),
      );
    } catch (e) {
      _logDebug("Error deleting image from StorageManager: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete image: $e')),
      );
    }
  }

  Future<void> _saveImageToGallery(File imageFile, String animalName) async {
    String? message;
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Create a filename with the animal name
      final fileName = 'animal_${animalName.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final tempPath = path.join(dir.path, fileName);

      // Create a copy in the temp directory
      final File tempFile = await imageFile.copy(tempPath);

      // Ask the user where to save it
      final params = SaveFileDialogParams(
        sourceFilePath: tempFile.path,
        fileName: fileName,
      );

      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        message = 'Image saved to gallery';
      }
    } catch (e) {
      message = 'Error saving image: $e';
      print(e);
    }

    if (message != null && mounted) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _saveAnalyzedImagesToDB() async {
    if (!_analysisComplete || _appImages.isEmpty || _animalLabels.isEmpty) {
      _logDebug("No analyzed images to save");
      return;
    }

    _logDebug("Saving ${_appImages.length} analyzed images to database");

    try {
      // Use the public getter for current user
      final currentUser = UserManager.getCurrentUser;

      if (currentUser == null || currentUser.id == null) {
        _logDebug("User not logged in or missing ID, using default username");

        // Try to find the user by username
        final userFromDB = await FirestoreService.getUserByUsername("PLACEHOLDER");

        if (userFromDB == null || userFromDB.id == null) {
          _logDebug("Failed to find user in database");

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please log in to save images to database'))
            );
          }
          return;
        }

        // Use the user from the database
        final String userId = userFromDB.id!;
        _logDebug("Using database user: $userId");

        await _processImageSaving(userId);
      } else {
        // User is logged in
        final String userId = currentUser.id!;
        _logDebug("User logged in: $userId");

        await _processImageSaving(userId);
      }
    } catch (e) {
      _logDebug("Error saving analyzed images to database: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save to database: $e'))
        );
      }
    }
  }

// Move the image saving logic to a separate method to avoid code duplication
  Future<void> _processImageSaving(String userId) async {
    int savedCount = 0;

    // For each image that has an animal label
    for (var imageFile in _appImages) {
      final fileName = path.basename(imageFile.path);
      final animalLabel = _getAnimalLabel(imageFile);

      // Skip images that weren't successfully analyzed
      if (animalLabel == 'Not analyzed') {
        _logDebug("Skipping image without analysis: $fileName");
        continue;
      }

      // Get location data using LocationManager
      List<double>? locationData;
      try {
        final position = await LocationManager().getPosition();
        if (position != null) {
          locationData = [position.latitude, position.longitude];
        }
      } catch (e) {
        _logDebug("Error getting location: $e");
      }

      // Create photo object with the correct structure
      var photoObject = PhotoObject(
        id: null,
        userId: userId,
        photoPath: imageFile.path,
        timestamp: DateTime.now(),
        location: locationData,
        animalClassification: null, // Will be updated after animal is saved
        encryptedImageData: await ImageEncryptor.encryptPngToString(imageFile),
      );

      // Check if animal already exists in database
      AnimalObject? existingAnimal;
      try {
        existingAnimal = await FirestoreService.getAnimalByName(animalLabel);
      } catch (e) {
        _logDebug("Error finding animal by name: $e");
      }

      AnimalObject animalToSave;

      if (existingAnimal == null) {
        // If this is a new animal, generate a new AnimalObject
        _logDebug("Creating new animal: $animalLabel");

        // Determine initial rarity - new discoveries are always legendary
        animalToSave = await AnimalService.generateAnimalObject(
            animalName: animalLabel,
            species: animalLabel,
            firstPhoto: photoObject,
            rarity: Rarity.legendary
        );
        _logDebug("Generated new animal object: ${animalToSave.name} with rarity ${animalToSave.rarity}");
      } else {
        // If animal exists, count how many photos we already have of it
        _logDebug("Animal already exists: $animalLabel (ID: ${existingAnimal.id})");

        // Get count of existing photos for this animal
        int photoCount = 1; // Start with 1 for the current photo
        try {
          if (existingAnimal.id != null) {
            final photos = await FirestoreService.getPhotosByAnimal(existingAnimal.id!);
            photoCount += photos.length;
          }
        } catch (e) {
          _logDebug("Error counting existing photos: $e");
        }

        // Update the existing animal
        animalToSave = await AnimalService.updateAnimalObject(
            existingAnimal: existingAnimal,
            newPhoto: photoObject,
            totalPhotoCount: photoCount
        );
        _logDebug("Updated animal object: ${animalToSave.name} with count $photoCount");
      }

      // Save the animal to database first
      String? animalId;
      try {
        animalId = await FirestoreService.saveAnimal(animalToSave);
        if (animalId == null || animalId.isEmpty) {
          _logDebug("Failed to save animal: ${animalToSave.name}");
          continue;
        }
        _logDebug("Animal saved with ID: $animalId");

        // Update the photo object with the animal classification
        photoObject = PhotoObject(
          id: photoObject.id,
          userId: photoObject.userId,
          photoPath: photoObject.photoPath,
          timestamp: photoObject.timestamp,
          location: photoObject.location,
          animalClassification: animalId, // Now we have the animal ID
          encryptedImageData: photoObject.encryptedImageData,
        );
      } catch (e) {
        _logDebug("Error saving animal: $e");
        continue;
      }

      // Now save the photo to database
      String? photoId;
      try {
        photoId = await FirestoreService.savePhoto(photoObject);

        if (photoId != null && photoId.isNotEmpty) {
          _logDebug("Photo saved with ID: $photoId");
          savedCount++;
        } else {
          _logDebug("Failed to save photo: $fileName");
        }
      } catch (e) {
        _logDebug("Error saving photo: $e");
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved $savedCount analyzed images to database'))
      );
    }

    _logDebug("Database save complete: $savedCount images saved");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadImagesFromStorage,
            tooltip: 'Refresh Gallery',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clearAll') {
                _clearAllImages();
              } else if (value == 'debug') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Debug Logs'),
                    content: SingleChildScrollView(
                      child: SelectableText(_debugLogs),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
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
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'clearAll',
                child: Text('Clear All Images'),
              ),
              const PopupMenuItem<String>(
                value: 'debug',
                child: Text('Show Debug Logs'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera and gallery buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImagesFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Import Photos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status bar for image count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.photo_library,
                  size: 16.0,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Images in Storage: ${_appImages.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Image grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _appImages.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No images in storage',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo or import from gallery',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadImagesFromStorage,
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: _appImages.length,
                itemBuilder: (context, index) {
                  final imageFile = _appImages[index];
                  final animalLabel = _analysisComplete ? _getAnimalLabel(imageFile) : 'Not analyzed';

                  return GestureDetector(
                    onTap: () => _showImageDetails(imageFile, animalLabel),
                    onLongPress: () => _showImageOptions(imageFile, animalLabel),
                    child: Card(
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
                                  imageFile,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    );
                                  },
                                ),
                                if (_analysisComplete)
                                  Positioned(
                                    right: 0,
                                    left: 0,
                                    bottom: 0,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              animalLabel,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              path.basename(imageFile.path),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Analysis button
          if (_appImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Processing...'),
                    ],
                  )
                      : const Text('Analyze Animals'),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 4),
    );
  }

  // Show options for the image
  void _showImageOptions(File imageFile, String animalLabel) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save to Gallery'),
              onTap: () {
                Navigator.pop(context);
                _saveImageToGallery(imageFile, animalLabel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Image Details'),
              onTap: () {
                Navigator.pop(context);
                _showImageDetails(imageFile, animalLabel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Image', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(imageFile);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show delete confirmation
  void _showDeleteConfirmation(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(imageFile);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Show image details
  void _showImageDetails(File imageFile, String animalLabel) {
    final fileName = path.basename(imageFile.path);
    final fileSize = (imageFile.lengthSync() / 1024).toStringAsFixed(2);

    // Try to extract timestamp from filename or get file modified time
    DateTime dateCreated;
    try {
      final nameParts = fileName.split('_');
      final timestamp = nameParts.last.split('.').first;
      dateCreated = DateTime.fromMillisecondsSinceEpoch(
          int.parse(timestamp),
          isUtc: true
      ).toLocal();
    } catch (e) {
      // Fall back to file stats
      dateCreated = File(imageFile.path).lastModifiedSync();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: 200,
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Filename: $fileName'),
              Text('File size: $fileSize KB'),
              Text('Date created: ${dateCreated.toString().split('.')[0]}'),
              Text('Animal: $animalLabel'),
              Text('Storage location: ${imageFile.path}'),
              Text('Managed by: StorageManager'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveImageToGallery(imageFile, animalLabel);
            },
            child: const Text('Save to Gallery'),
          ),
        ],
      ),
    );
  }
}

enum PermissionType {
  camera,
  gallery
}