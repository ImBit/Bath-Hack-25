import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../widgets/bottom_navigation.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? controller;
  List<CameraDescription> cameras = [];
  File? imageFile;
  bool isCapturing = false;
  bool isFlashOn = false;
  int selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
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

    // App state changed before camera was initialized
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      _onNewCameraSelected(cameras[selectedCameraIndex]);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        _showMessage('No cameras found');
        return;
      }

      _onNewCameraSelected(cameras[selectedCameraIndex]);
    } on CameraException catch (e) {
      _showCameraException(e);
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }

    // Create a new camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();

      // Reset flash when switching to front camera
      if (cameraDescription.lensDirection == CameraLensDirection.front) {
        setState(() {
          isFlashOn = false;
        });
        await cameraController.setFlashMode(FlashMode.off);
      }
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _toggleFlash() async {
    if (controller == null || !controller!.value.isInitialized) return;

    if (controller!.description.lensDirection == CameraLensDirection.front) {
      _showMessage('Flash not available on front camera');
      return;
    }

    try {
      final newFlashMode = isFlashOn ? FlashMode.off : FlashMode.torch;
      await controller!.setFlashMode(newFlashMode);

      setState(() {
        isFlashOn = !isFlashOn;
      });
    } on CameraException catch (e) {
      _showCameraException(e);
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
        imageFile = File(file.path);
        isCapturing = false;
      });

      _showMessage('Photo captured!');
    } on CameraException catch (e) {
      _showCameraException(e);
    } finally {
      if (mounted) {
        setState(() {
          isCapturing = false;
        });
      }
    }
  }

  void _resetCamera() {
    setState(() {
      imageFile = null;
    });
  }

  void _saveImage() {
    // Implement image saving logic here
    _showMessage('Image saved!');
    // Navigate to image preview screen if needed
    // Navigator.pushNamed(context, '/image-preview', arguments: imageFile);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }

  void _showCameraException(CameraException e) {
    _showMessage('Error: ${e.code}\n${e.description}');
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
      body: _buildBody(),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    // Show the captured image if available
    if (imageFile != null) {
      return _buildCapturedImageView();
    }

    // Show camera preview if controller is initialized
    if (controller != null && controller!.value.isInitialized) {
      return _buildCameraPreview();
    }

    // Show loading indicator while camera initializes
    return _buildLoadingView();
  }

  Widget _buildCapturedImageView() {
    return Stack(
      children: [
        // Image preview
        SizedBox.expand(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Image.file(
              imageFile!,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.black.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.close,
                  label: 'Discard',
                  onPressed: _resetCamera,
                ),
                _buildControlButton(
                  icon: Icons.check,
                  label: 'Save',
                  onPressed: _saveImage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final scale = 1 / (controller!.value.aspectRatio * deviceRatio);

    return Stack(
      children: [
        // Camera preview
        Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Center(
            child: CameraPreview(controller!),
          ),
        ),

        // Top control bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),
        ),

        // Bottom control bar
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
                // Gallery button
                IconButton(
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/gallery');
                  },
                ),

                // Camera capture button
                GestureDetector(
                  onTap: isCapturing ? null : _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: isCapturing ? Colors.grey : Colors.transparent,
                    ),
                    child: Center(
                      child: isCapturing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                // Switch camera button
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

        // Camera guide grid
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 28),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

// Custom painter for camera guide grid
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // Horizontal lines
    final double horizontalStep = size.height / 3;
    for (int i = 1; i < 3; i++) {
      final double y = horizontalStep * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    final double verticalStep = size.width / 3;
    for (int i = 1; i < 3; i++) {
      final double x = verticalStep * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}