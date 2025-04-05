import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageEncryptor {
  // Encrypt a PNG image file to a Base64 string
  static Future<String> encryptPngToString(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
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