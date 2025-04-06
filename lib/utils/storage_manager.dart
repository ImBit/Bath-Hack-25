import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageManager {
  static final StorageManager _instance = StorageManager._internal();

  factory StorageManager() {
    return _instance;
  }

  StorageManager._internal();

  Future<Directory> get appDir async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/animal_images');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  Future<List<File>> getAllImages() async {
    final dir = await appDir;
    List<File> images = [];

    try {
      final entities = await dir.list().toList();

      for (var entity in entities) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png'].contains(extension)) {
            images.add(entity);
          }
        }
      }

      images.sort((a, b) => b.path.compareTo(a.path));

    } catch (e) {
      print("Error getting images from storage: $e");
      rethrow;
    }

    return images;
  }

  Future<File> saveImage(File sourceImage) async {
    final dir = await appDir;
    final extension = path.extension(sourceImage.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final newPath = path.join(dir.path, 'image_${timestamp}$extension');

    try {
      return await sourceImage.copy(newPath);
    } catch (e) {
      print("Error saving image to storage: $e");
      rethrow;
    }
  }

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