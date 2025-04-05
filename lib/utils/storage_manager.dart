import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageManager {
  static final StorageManager _instance = StorageManager._internal();

  factory StorageManager() {
    return _instance;
  }

  StorageManager._internal();

  /// Get the application documents directory
  Future<Directory> get appDir async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/animal_images');

    // Create directory if it doesn't exist
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  /// Get all images from app storage
  Future<List<File>> getAllImages() async {
    final dir = await appDir;
    List<File> images = [];

    try {
      final entities = await dir.list().toList();

      // Filter to only get image files
      for (var entity in entities) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png'].contains(extension)) {
            images.add(entity);
          }
        }
      }

      // Sort by newest first (assuming filename contains timestamp)
      images.sort((a, b) => b.path.compareTo(a.path));

    } catch (e) {
      print("Error getting images from storage: $e");
      rethrow;
    }

    return images;
  }

  /// Save an image to app storage
  Future<File> saveImage(File sourceImage) async {
    final dir = await appDir;
    final extension = path.extension(sourceImage.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final newPath = path.join(dir.path, 'image_${timestamp}$extension');

    try {
      // Copy the image to app storage
      return await sourceImage.copy(newPath);
    } catch (e) {
      print("Error saving image to storage: $e");
      rethrow;
    }
  }

  /// Delete an image from app storage
  Future<void> deleteImage(File image) async {
    try {
      if (await image.exists()) {
        await image.delete();
      }
    } catch (e) {
      print("Error deleting image from storage: $e");
      rethrow;
    }
  }

  /// Clear all images from app storage
  Future<void> clearAllImages() async {
    final dir = await appDir;

    try {
      final entities = await dir.list().toList();

      for (var entity in entities) {
        if (entity is File) {
          await entity.delete();
        }
      }
    } catch (e) {
      print("Error clearing images from storage: $e");
      rethrow;
    }
  }
}