import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../screens/journal_screen.dart';

class PhotoObject {
  String? id;
  final String photoPath;
  final DateTime timestamp;
  final String? animalClassification;
  final List<double>? location; // [latitude, longitude]
  final String userId;
  final String? encryptedImageData;

  PhotoObject({
    this.id,
    required this.photoPath,
    required this.timestamp,
    this.animalClassification,
    this.location,
    required this.userId,
    this.encryptedImageData,
  });

  // Convert PhotoObject to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'photoPath': photoPath,
      'timestamp': timestamp,
      'animalClassification': animalClassification,
      'location': location, // List with [latitude, longitude]
      'userId': userId,
      'encryptedImageData': encryptedImageData,
    };
  }

  // Create PhotoObject from Firestore data
  factory PhotoObject.fromMap(Map<String, dynamic> map, {String? docId}) {
    // Handle location data as a list
    List<double>? locationData;
    if (map['location'] != null) {
      if (map['location'] is List) {
        locationData = (map['location'] as List)
            .map((item) => item is double ? item : (item as num).toDouble())
            .toList();
      }
    }

    return PhotoObject(
      id: docId,
      photoPath: map['photoPath'] ?? '',
      timestamp: (map['timestamp'] is DateTime)
          ? map['timestamp']
          : (map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now()),
      animalClassification: map['animalClassification'],
      location: locationData,
      userId: map['userId'] ?? '',
      encryptedImageData: map['encryptedImageData'],
    );
  }

  // Get image as ImageProvider if available
  ImageProvider? getImageProvider() {
    if (encryptedImageData != null && encryptedImageData!.isNotEmpty) {
      try {
        final Uint8List imageBytes = base64Decode(encryptedImageData!);
        return MemoryImage(imageBytes);
      } catch (e) {
        print("Error decoding image: $e");
        return null;
      }
    }
    return null;
  }

  // Get latitude and longitude as LatLng object
  LatLng? getLatLng() {
    if (location != null && location!.length >= 2) {
      return LatLng(location![0], location![1]);
    }
    return null;
  }

  @override
  String toString() {
    return 'PhotoObject(id: $id, photoPath: $photoPath, timestamp: $timestamp, '
        'animalClassification: $animalClassification, location: $location, '
        'userId: $userId, hasEncryptedImage: ${encryptedImageData != null})';
  }
}

class AnimalObject {
  String? id;
  final String name;
  final String species;
  final String description;
  final String rarity;
  final String? encryptedImageData; // Base64 encoded encrypted image data

  AnimalObject({
    this.id,
    required this.name,
    required this.species,
    required this.description,
    required this.rarity,
    this.encryptedImageData,
  });

  // Convert AnimalObject to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'species': species,
      'description': description,
      'rarity': rarity,
      'encryptedExampleImageData': encryptedImageData
    };
  }

  // Create AnimalObject from Firestore data
  factory AnimalObject.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AnimalObject(
      id: docId,
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      description: map['description'] ?? '',
      rarity: map['rarity'] ?? '',
      encryptedImageData: map['encryptedExampleImageData'],
    );
  }

  static Rarity fromString(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common': // Rarity.common.name
        return Rarity.common;
      case 'uncommon': // Rarity.uncommon.name
        return Rarity.uncommon;
      case 'rare': // Rarity.rare.name
        return Rarity.rare;
      case 'legendary': // Rarity.legendary.name
        return Rarity.legendary;
      default:
        throw ArgumentError('Unknown rarity: $rarity');
    }
  }

  String toReadableString() {
    return toString().split('.').last.replaceAll('_', ' ');
  }

  ImageProvider? getImageProvider() {
    if (encryptedImageData != null && encryptedImageData!.isNotEmpty) {
      try {
        final Uint8List imageBytes = base64Decode(encryptedImageData!);
        return MemoryImage(imageBytes);
      } catch (e) {
        print("Error decoding example image: $e");
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'AnimalObject(id: $id, name: $name, species: $species, '
        'description: $description, rarity: $rarity, hasExampleImage: ${encryptedImageData != null})';
  }
}