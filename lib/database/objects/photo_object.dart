import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PhotoObject {
  String? id;
  final String photoPath;
  final DateTime timestamp;
  final String? animalClassification; // ID or name of the animal
  final Map<String, double>? location; // Now a Map with latitude and longitude
  final String userId;

  PhotoObject({
    this.id,
    required this.photoPath,
    required this.timestamp,
    this.animalClassification,
    this.location,
    required this.userId,
  });

  // Convert PhotoObject to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'photoPath': photoPath,
      'timestamp': timestamp,
      'animalClassification': animalClassification,
      'location': location, // Now a Map with latitude and longitude
      'userId': userId,
    };
  }

  // Create PhotoObject from Firestore data
  factory PhotoObject.fromMap(Map<String, dynamic> map, {String? docId}) {
    return PhotoObject(
      id: docId,
      photoPath: map['photoPath'] ?? '',
      timestamp: (map['timestamp'] is DateTime)
          ? map['timestamp']
          : (map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now()),
      animalClassification: map['animalClassification'],
      location: map['location'] != null
          ? (map['location'] as Map<String, dynamic>).map((key, value) =>
          MapEntry(key, value is double ? value : (value as num).toDouble()))
          : null,
      userId: map['userId'] ?? '',
    );
  }

  @override
  String toString() {
    return 'PhotoObject(id: $id, photoPath: $photoPath, timestamp: $timestamp, animalClassification: $animalClassification, location: $location, userId: $userId)';
  }
}

class AnimalObject {
  String? id;
  final String name;
  final String species;
  final String description;
  final String? examplePhotoUrl;

  AnimalObject({
    this.id,
    required this.name,
    required this.species,
    required this.description,
    this.examplePhotoUrl,
  });

  // Convert AnimalObject to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'species': species,
      'description': description,
      'examplePhotoUrl': examplePhotoUrl,
    };
  }

  // Create AnimalObject from Firestore data
  factory AnimalObject.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AnimalObject(
      id: docId,
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      description: map['description'] ?? '',
      examplePhotoUrl: map['examplePhotoUrl'],
    );
  }

  @override
  String toString() {
    return 'AnimalObject(id: $id, name: $name, species: $species, description: $description, examplePhotoUrl: $examplePhotoUrl)';
  }
}