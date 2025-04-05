import 'dart:io';
import 'package:animal_conservation/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../widgets/bottom_navigation.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? controller;
  List<CameraDescription> cameras = [];
  dynamic imageFile; // DEPENDS ON PLATFORM: Will be File or XFile
  bool isCapturing = false;
  int selectedCameraIndex = 0;
  bool showingPreview = false;
  String _savedImagePath = '';

  // Directory where we'll save our images
  Directory? _appDirectory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initAppDirectory();
  }

  Future<void> _initAppDirectory() async {
    try {
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/animal_images');

      // Create the directory if it doesn't exist
      if (!(await imagesDir.exists())) {
        await imagesDir.create(recursive: true);
      }

      _appDirectory = imagesDir;
      print("App directory initialized: ${imagesDir.path}");
    } catch (e) {
      print("Error initializing app directory: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(cameras[selectedCameraIndex]);
    }
  }

  Future<void> _requestStoragePermissions() async {
    if (kIsWeb) return; // No need for permissions on web

    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      if (Platform.isAndroid && await Permission.manageExternalStorage.isGranted)
        Permission.manageExternalStorage,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      _showMessage('Storage permission is required to save images');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (!kIsWeb) {
        cameras = await availableCameras();

        if (cameras.isEmpty) {
          _showMessage('No cameras found');
          return;
        }

        _onNewCameraSelected(cameras[selectedCameraIndex]);
      }
    } catch (e) {
      _showMessage('Error initializing camera: ${e.toString()}');
    }
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
    } catch (e) {
      _showMessage('Error initializing camera controller: ${e.toString()}');
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _toggleCamera() {
    if (cameras.isEmpty || cameras.length < 2) return;

    setState(() {
      selectedCameraIndex = selectedCameraIndex == 0 ? 1 : 0;
    });

    _onNewCameraSelected(cameras[selectedCameraIndex]);
  }

  Future<void> _takePicture() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      _showMessage('Camera is not initialized');
      return;
    }

    if (isCapturing) return;

    try {
      setState(() {
        isCapturing = true;
      });

      final XFile file = await cameraController.takePicture();

      setState(() {
        imageFile = file;
        isCapturing = false;
      });

      _showImagePreview();

    } catch (e) {
      _showMessage('Error taking picture: ${e.toString()}');
      setState(() {
        isCapturing = false;
      });
    }
  }

  Future<void> _uploadFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        return;
      }

      setState(() {
        imageFile = pickedFile;
      });

      _showImagePreview();

    } catch (e) {
      _showMessage('Error picking image: ${e.toString()}');
    }
  }

  void _showImagePreview() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: _buildImageWidget(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetCamera();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _processUpload();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processUpload() async {
    if (imageFile == null || _appDirectory == null) {
      _showMessage('Unable to save image');
      return;
    }

    try {
      // Request storage permissions first
      await _requestStoragePermissions();

      // Generate a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalFilename = imageFile is XFile
          ? path.basename((imageFile as XFile).path)
          : 'animal_$timestamp.jpg';

      final fileName = 'animal_${timestamp}_${originalFilename}';
      final savedFilePath = path.join(_appDirectory!.path, fileName);

      // Copy the file to our app's directory
      File sourceFile;
      if (imageFile is XFile) {
        sourceFile = File((imageFile as XFile).path);
      } else if (imageFile is File) {
        sourceFile = imageFile;
      } else {
        throw Exception('Unsupported image type');
      }

      // Copy the file
      final savedFile = await sourceFile.copy(savedFilePath);

      setState(() {
        _savedImagePath = savedFilePath;
      });

      _showMessage('Image saved successfully at: $savedFilePath');

      // Show options dialog
      _showSavedImageOptions(savedFile);

    } catch (e) {
      _showMessage('Error saving image: $e');
    } finally {
      _resetCamera();
    }
  }

  void _showSavedImageOptions(File savedFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image Saved Successfully'),
          content: SingleChildScrollView( // Wrap in SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keep this to minimize height
              children: [
                // Fix 1: Add constraints to the image
                Container(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: ClipRRect( // Optional: adds rounded corners
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      savedFile,
                      fit: BoxFit.contain, // Use contain instead of cover
                      // Don't specify height/width here, let Container constrain it
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Saved to: ${path.basename(savedFile.path)}'),
                const SizedBox(height: 16),
                const Text('What would you like to do next?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.gallery);
              },
              child: const Text('Go to Gallery'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Take Another Photo'),
            ),
          ],
        );
      },
    );
  }

  void _resetCamera() {
    setState(() {
      imageFile = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBody(),
          _buildAlwaysVisibleUploadButton(),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildAlwaysVisibleUploadButton() {
    if (!kIsWeb && controller != null && controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _uploadFromGallery,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.file_upload,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!kIsWeb && controller != null && controller!.value.isInitialized) {
      return _buildCameraPreview();
    }

    return _buildLoadingView();
  }

  Widget _buildImageWidget() {
    if (imageFile == null) {
      return Container();
    }

    if (kIsWeb) {
      if (imageFile is XFile) {
        return FutureBuilder<String>(
          future: (imageFile as XFile).readAsString(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return Image.network(
                snapshot.data!,
                fit: BoxFit.contain,
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      } else {
        return const Center(child: Text('Unsupported image format', style: TextStyle(color: Colors.white)));
      }
    } else {
      if (imageFile is XFile) {
        return Image.file(
          File((imageFile as XFile).path),
          fit: BoxFit.contain,
        );
      } else if (imageFile is File) {
        return Image.file(
          imageFile,
          fit: BoxFit.contain,
        );
      } else {
        return const Center(child: Text('Unsupported image format', style: TextStyle(color: Colors.white)));
      }
    }
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final scale = 1 / (controller!.value.aspectRatio * deviceRatio);

    return Stack(
      children: [
        Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Center(
            child: CameraPreview(controller!),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            color: Colors.black.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _uploadFromGallery,
                ),

                GestureDetector(
                  onTap: isCapturing ? null : _takePicture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: isCapturing ? Colors.grey : Colors.transparent,
                    ),
                    child: Center(
                      child: isCapturing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: cameras.length > 1 ? _toggleCamera : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!kIsWeb)
              const CircularProgressIndicator(color: Colors.white),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Camera is not available on web.\nPlease use the upload button.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}