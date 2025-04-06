import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // Add this package for image processing

class ImageEncryptor {
  // Static variable for image size that can be changed if needed
  static int targetImageSize = 100;

  // Resize and crop image to square dimensions before encryption
  static Future<Uint8List> _processImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception("Failed to decode image");

    // Calculate dimensions for cropping to square
    final size = image.width < image.height ? image.width : image.height;
    final xOffset = (image.width - size) ~/ 2;
    final yOffset = (image.height - size) ~/ 2;

    // Crop to square from center
    final croppedImage = img.copyCrop(
      image,
      x: xOffset,
      y: yOffset,
      width: size,
      height: size,
    );

    // Resize to target dimensions
    final resizedImage = img.copyResize(
      croppedImage,
      width: targetImageSize,
      height: targetImageSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert back to PNG bytes
    return Uint8List.fromList(img.encodePng(resizedImage));
  }

  // Encrypt a PNG image file to a Base64 string
  static Future<String> encryptPngToString(File imageFile) async {
    try {
      final processedImageBytes = await _processImage(imageFile);
      final base64String = base64Encode(processedImageBytes);
      return base64String;
    } catch (e) {
      print("Error encrypting image: $e");
      throw Exception("Failed to encrypt image");
    }
  }

  // Decrypt a Base64 string back to image bytes
  static Uint8List decryptStringToBytes(String encodedImage) {
    try {
      if (encodedImage == "--pfp--") {
        // Return default image bytes or throw an exception
        throw Exception("No profile picture set");
      }

      final bytes = base64Decode(encodedImage);
      return bytes;
    } catch (e) {
      print("Error decrypting image: $e");
      throw Exception("Failed to decrypt image");
    }
  }

  // Create an Image provider from the encrypted string
  static ImageProvider createImageFromEncryptedString(String encodedImage) {
    try {
      if (encodedImage == "--pfp--") {
        return const AssetImage('assets/images/default_profile.png');
      }

      final bytes = decryptStringToBytes(encodedImage);
      return MemoryImage(bytes);
    } catch (e) {
      print("Error creating image from encrypted string: $e");
      // Return a default image on error
      return const AssetImage('assets/images/default_profile.png');
    }
  }
}