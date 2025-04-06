import 'dart:async';
import 'dart:io';
import 'dart:math' as Math;
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
import '../utils/rarity.dart';
import '../utils/storage_manager.dart';

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
  List<File> _submittedImages = [];

  @override
  void initState() {
    super.initState();
    _loadImagesFromStorage();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _loadingTimer?.cancel();
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

      if (images.isNotEmpty && _animalLabels.isEmpty) {
        setState(() {
          _analysisComplete = false;
        });
      }
    } catch (e) {
      _logDebug("Error loading images from StorageManager: $e");
      setState(() {
        _isLoading = false;
        _appImages = [];
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

  Future<void> _clearAllImages() async {
    try {
      _logDebug("Clearing all images from StorageManager");

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

  double _loadingProgress = 0.0;
  Timer? _loadingTimer;
  DateTime? _loadingStartTime;


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
      _submittedImages = [];
      _loadingProgress = 0.0;
      _loadingStartTime = DateTime.now();
    });

    // Start the loading timer with inverse progression
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final elapsedSeconds = DateTime.now().difference(_loadingStartTime!).inMilliseconds / 1000;

      // Inverse formula: progress = 1 - (1 / (1 + rate * time))
      // This will create the effect of slowing down as it progresses
      // Rate of 0.1 means it takes ~5s to reach 50%, ~10s to reach 75%, ~15s to reach 87.5%, etc.
      final newProgress = 1 - (1 / (1 + 0.075 * elapsedSeconds*elapsedSeconds));

      setState(() {
        _loadingProgress = newProgress;

        // If actual processing completes, we'll cancel this in _checkDetectionStatus
        // But we'll cap at 99% for visual purposes until real completion
        if (_loadingProgress >= 0.99) {
          _loadingProgress = 0.99;
        }
      });
    });

    try {
      _logDebug("Sending ${_appImages.length} images to API for analysis");

      final response = await _api.startDetection(_appImages);
      _logDebug("API response: $response");

      if (response.containsKey('session_id')) {
        _sessionId = response['session_id'];
        _logDebug("Got session ID: $_sessionId");

        _statusCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _checkDetectionStatus();
        });
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      _loadingTimer?.cancel(); // Cancel loading timer on error
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
        _loadingTimer?.cancel(); // Cancel the loading timer when complete

        Map<String, String> labels = {};
        for (var result in statusResponse['results']) {
          labels[result['filename']] = result['animal'];
        }

        setState(() {
          _animalLabels = labels;
          _analysisComplete = true;
          _isProcessing = false;
          _loadingProgress = 1.0; // Jump to 100% when actually complete
        });

        _logDebug("Results parsed: ${labels.length} labels");

        await _saveAnalysedImagesToDB();
      } else {
        _logDebug("Still processing...");
      }
    } catch (e) {
      _logDebug("Error checking status: $e");
    }
  }

  String _getAnimalLabel(File imageFile) {
    final fileName = path.basename(imageFile.path);

    if (_animalLabels.containsKey(fileName)) {
      return _animalLabels[fileName]!;
    }

    for (var key in _animalLabels.keys) {
      if (key.toLowerCase() == fileName.toLowerCase()) {
        return _animalLabels[key]!;
      }
    }

    return 'Not analysed';
  }

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

      final fileName = 'animal_${animalName.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final dir = await getTemporaryDirectory();
      final tempPath = path.join(dir.path, fileName);

      final File tempFile = await imageFile.copy(tempPath);

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

  Future<void> _saveAnalysedImagesToDB() async {
    if (!_analysisComplete || _appImages.isEmpty || _animalLabels.isEmpty) {
      _logDebug("No analysed images to save");
      return;
    }

    _logDebug("Saving ${_appImages.length} analysed images to database");

    try {
      final currentUser = UserManager.getCurrentUser;

      if (currentUser == null || currentUser.id == null) {
        _logDebug("User not logged in or missing ID, using default username");

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

        final String userId = userFromDB.id!;
        _logDebug("Using database user: $userId");

        await _processImageSaving(userId);
      } else {
        final String userId = currentUser.id!;
        _logDebug("User logged in: $userId");

        await _processImageSaving(userId);
      }
    } catch (e) {
      _logDebug("Error saving analysed images to database: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save to database: $e'))
        );
      }
    }
  }

  Future<void> _processImageSaving(String userId) async {
    int savedCount = 0;
    List<File> imagesToRemove = [];
    Map<File, String> successfullySubmitted = {};

    // Set to track files that are already being deleted to prevent duplicates
    Set<String> processingPaths = {};

    for (var imageFile in _appImages) {
      // Skip this file if we've already processed it
      if (processingPaths.contains(imageFile.path)) {
        continue;
      }

      // Mark this file as being processed
      processingPaths.add(imageFile.path);

      final fileName = path.basename(imageFile.path);
      final animalLabel = _getAnimalLabel(imageFile);

      // Check if file exists before attempting operations
      bool fileExists;
      try {
        fileExists = await imageFile.exists();
      } catch (e) {
        _logDebug("Error checking if file exists: $e");
        fileExists = false;
      }

      if (!fileExists) {
        _logDebug("Skipping non-existent file: $fileName");
        imagesToRemove.add(imageFile);
        continue;
      }

      if (animalLabel.toLowerCase() == 'blank') {
        _logDebug("Detected blank image: $fileName - removing directly");
        try {
          await _storageManager.deleteImage(imageFile);
          imagesToRemove.add(imageFile);
        } catch (e) {
          _logDebug("Error removing blank image: $e");
          // Still add to removal list even if deletion fails
          imagesToRemove.add(imageFile);
        }
        continue;
      }

      if (animalLabel == 'Not analysed') {
        _logDebug("Skipping image without analysis: $fileName");
        continue;
      }

      List<double>? locationData;
      try {
        final position = await LocationManager().getPosition();
        if (position != null) {
          locationData = [position.latitude, position.longitude];
        }
      } catch (e) {
        _logDebug("Error getting location: $e");
      }

      var photoObject = PhotoObject(
        id: null,
        userId: userId,
        photoPath: imageFile.path,
        timestamp: DateTime.now(),
        location: locationData,
        animalClassification: null,
        encryptedImageData: await ImageEncryptor.encryptPngToString(imageFile),
      );

      AnimalObject? existingAnimal;
      try {
        existingAnimal = await FirestoreService.getAnimalByName(animalLabel);
      } catch (e) {
        _logDebug("Error finding animal by name: $e");
      }

      AnimalObject animalToSave;

      if (existingAnimal == null) {
        _logDebug("Creating new animal: $animalLabel");

        animalToSave = await AnimalService.generateAnimalObject(
            animalName: animalLabel,
            species: animalLabel,
            firstPhoto: photoObject,
            rarity: Rarity.legendary
        );
        _logDebug("Generated new animal object: ${animalToSave
            .name} with rarity ${animalToSave.rarity}");
      } else {
        _logDebug(
            "Animal already exists: $animalLabel (ID: ${existingAnimal.id})");

        int photoCount = 1;
        try {
          if (existingAnimal.id != null) {
            final photos = await FirestoreService.getPhotosByAnimal(
                existingAnimal.id!);
            photoCount += photos.length;
          }
        } catch (e) {
          _logDebug("Error counting existing photos: $e");
        }

        animalToSave = await AnimalService.updateAnimalObject(
            existingAnimal: existingAnimal,
            newPhoto: photoObject,
            totalPhotoCount: photoCount
        );
        _logDebug("Updated animal object: ${animalToSave
            .name} with count $photoCount");
      }

      String? animalId;
      try {
        animalId = await FirestoreService.saveAnimal(animalToSave);
        if (animalId == null || animalId.isEmpty) {
          _logDebug("Failed to save animal: ${animalToSave.name}");
          continue;
        }
        _logDebug("Animal saved with ID: $animalId");

        photoObject = PhotoObject(
          id: photoObject.id,
          userId: photoObject.userId,
          photoPath: photoObject.photoPath,
          timestamp: photoObject.timestamp,
          location: photoObject.location,
          animalClassification: animalId,
          encryptedImageData: photoObject.encryptedImageData,
        );
      } catch (e) {
        _logDebug("Error saving animal: $e");
        continue;
      }

      String? photoId;
      try {
        photoId = await FirestoreService.savePhoto(photoObject);

        if (photoId != null && photoId.isNotEmpty) {
          _logDebug("Photo saved with ID: $photoId");
          savedCount++;

          imagesToRemove.add(imageFile);
          successfullySubmitted[imageFile] = animalLabel;
        } else {
          _logDebug("Failed to save photo: $fileName");
        }
      } catch (e) {
        _logDebug("Error saving photo: $e");
      }
    }

    int blankImageCount = imagesToRemove
        .where((image) => !successfullySubmitted.containsKey(image))
        .length;

    if (successfullySubmitted.isNotEmpty || blankImageCount > 0) {
      if (mounted) {
        await _showSubmissionSummary(successfullySubmitted, 0);
      }

      for (var image in imagesToRemove) {
        try {
          if (await image.exists()) {
            await image.delete();
          }
          await _storageManager.deleteImage(image);
          _logDebug("Removed submitted image from storage: ${image.path}");
        } catch (e) {
          _logDebug("Error removing submitted image: $e");
        }
      }

      setState(() {
        _appImages.removeWhere((image) => imagesToRemove.contains(image));
      });

      // Rest of your code for showing summary etc.
      int blankImageCount = imagesToRemove
          .where(
              (image) => !successfullySubmitted.containsKey(image)
      )
          .length;

      if (successfullySubmitted.isNotEmpty || blankImageCount > 0) {
        if (mounted) {
          await _showSubmissionSummary(successfullySubmitted, blankImageCount);
        }
      }

      // Load fresh images after processing
      await _loadImagesFromStorage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Saved $savedCount analysed images to database'))
        );
      }

      _logDebug("Database save complete: $savedCount images saved");
    }
  }

  Future<void> _showSubmissionSummary(Map<File, String> submittedImages, int blankImageCount) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submission Summary'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (submittedImages.isNotEmpty) ...[
                  const Text('Successfully submitted:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...submittedImages.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              entry.key,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteImage(File imageFile) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      print("Error deleting image file: $e");
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Gallery'),
        backgroundColor: const Color.fromRGBO(255, 166, 0, 1),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _appImages.isEmpty
                ? null
                : () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Processed Images'),
                  content: const Text('Do you want to delete all processed images?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteProcessedImages();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Delete Processed Images',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  final animalLabel = _analysisComplete ? _getAnimalLabel(imageFile) : 'Not analysed';

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
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _loadingProgress,
                          backgroundColor: Colors.white30,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Processing... ${(_loadingProgress * 100).toInt()}%'),
                    ],
                  )
                      : const Text('Submit Findings!'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteProcessedImages() async {
    try {
      _logDebug("Manually deleting processed images");
      List<File> imagesToRemove = [];

      for (var imageFile in _appImages) {
        if (_analysisComplete && _getAnimalLabel(imageFile) != 'Not analysed') {
          imagesToRemove.add(imageFile);
        }
      }

      if (imagesToRemove.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No processed images to delete')),
        );
        return;
      }

      for (var image in imagesToRemove) {
        try {
          await _storageManager.deleteImage(image);
          _logDebug("Manually removed image: ${image.path}");
        } catch (e) {
          _logDebug("Error removing image manually: $e");
        }
      }

      setState(() {
        _appImages.removeWhere((image) => imagesToRemove.contains(image));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${imagesToRemove.length} processed images')),
      );
    } catch (e) {
      _logDebug("Error in manual deletion: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting images: $e')),
      );
    }
  }

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

  void _showImageDetails(File imageFile, String animalLabel) {
    final fileName = path.basename(imageFile.path);
    final fileSize = (imageFile.lengthSync() / 1024).toStringAsFixed(2);

    DateTime dateCreated;
    try {
      final nameParts = fileName.split('_');
      final timestamp = nameParts.last.split('.').first;
      dateCreated = DateTime.fromMillisecondsSinceEpoch(
          int.parse(timestamp),
          isUtc: true
      ).toLocal();
    } catch (e) {
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