import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'objects/user_object.dart';
import 'objects/photo_object.dart';

class FirestoreService {
  // Initialize Firebase (only once is better)
  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Already initialized
    }
  }

  // Get FirebaseFirestore instance
  Future<FirebaseFirestore> get _db async {
    await _initializeFirebase();
    return FirebaseFirestore.instance;
  }

  // Existing user-related functions...
  // ...

  // PHOTO RELATED FUNCTIONS

  // Save or update photo
  Future<String?> savePhoto(PhotoObject photo) async {
    final db = await _db;
    try {
      if (photo.id != null) {
        // Update existing photo
        await db.collection("photos").doc(photo.id).update(photo.toMap());
        return photo.id;
      } else {
        // Create new photo
        final docRef = await db.collection("photos").add(photo.toMap());
        return docRef.id;
      }
    } catch (e) {
      print("Error saving photo: $e");
      return null;
    }
  }

  // Get photo by ID
  Future<PhotoObject?> getPhotoById(String photoId) async {
    final db = await _db;
    try {
      final docSnapshot = await db.collection("photos").doc(photoId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return PhotoObject.fromMap(data, docId: docSnapshot.id);
      }
      return null;
    } catch (e) {
      print("Error getting photo by ID: $e");
      return null;
    }
  }

  // Get all photos for a user
  Future<List<PhotoObject>> getPhotosByUser(String userId) async {
    final db = await _db;
    try {
      final querySnapshot = await db
          .collection("photos")
          .where("userId", isEqualTo: userId)
          .orderBy("timestamp", descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return PhotoObject.fromMap(
            doc.data() as Map<String, dynamic>,
            docId: doc.id
        );
      }).toList();
    } catch (e) {
      print("Error getting photos by user: $e");
      return [];
    }
  }

  // Get photos by animal classification
  Future<List<PhotoObject>> getPhotosByAnimal(String animalClassification) async {
    final db = await _db;
    try {
      final querySnapshot = await db
          .collection("photos")
          .where("animalClassification", isEqualTo: animalClassification)
          .orderBy("timestamp", descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return PhotoObject.fromMap(
            doc.data() as Map<String, dynamic>,
            docId: doc.id
        );
      }).toList();
    } catch (e) {
      print("Error getting photos by animal: $e");
      return [];
    }
  }

  // Delete photo
  Future<bool> deletePhoto(String photoId) async {
    final db = await _db;
    try {
      await db.collection("photos").doc(photoId).delete();
      return true;
    } catch (e) {
      print("Error deleting photo: $e");
      return false;
    }
  }

  // Update photo with animal classification
  Future<bool> classifyPhoto(String photoId, String animalClassificationId) async {
    final db = await _db;
    try {
      await db.collection("photos").doc(photoId).update({
        'animalClassification': animalClassificationId
      });
      return true;
    } catch (e) {
      print("Error classifying photo: $e");
      return false;
    }
  }

  // ANIMAL RELATED FUNCTIONS

  // Save or update animal
  Future<String?> saveAnimal(AnimalObject animal) async {
    final db = await _db;
    try {
      if (animal.id != null) {
        // Update existing animal
        await db.collection("animals").doc(animal.id).update(animal.toMap());
        return animal.id;
      } else {
        // Check if animal with this name already exists
        final existingAnimal = await getAnimalByName(animal.name);
        if (existingAnimal != null) {
          print("Animal with name ${animal.name} already exists");
          return existingAnimal.id;
        }
        // Create new animal
        final docRef = await db.collection("animals").add(animal.toMap());
        return docRef.id;
      }
    } catch (e) {
      print("Error saving animal: $e");
      return null;
    }
  }

  // Get animal by ID
  Future<AnimalObject?> getAnimalById(String animalId) async {
    final db = await _db;
    try {
      final docSnapshot = await db.collection("animals").doc(animalId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return AnimalObject.fromMap(data, docId: docSnapshot.id);
      }
      return null;
    } catch (e) {
      print("Error getting animal by ID: $e");
      return null;
    }
  }

  // Get animal by name
  Future<AnimalObject?> getAnimalByName(String name) async {
    final db = await _db;
    try {
      final querySnapshot = await db
          .collection("animals")
          .where("name", isEqualTo: name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return AnimalObject.fromMap(
            doc.data() as Map<String, dynamic>,
            docId: doc.id
        );
      }
      return null;
    } catch (e) {
      print("Error getting animal by name: $e");
      return null;
    }
  }

  // Get all animals
  Future<List<AnimalObject>> getAllAnimals() async {
    final db = await _db;
    try {
      final querySnapshot = await db
          .collection("animals")
          .orderBy("name")
          .get();

      return querySnapshot.docs.map((doc) {
        return AnimalObject.fromMap(
            doc.data() as Map<String, dynamic>,
            docId: doc.id
        );
      }).toList();
    } catch (e) {
      print("Error getting all animals: $e");
      return [];
    }
  }

  // Get animals by species
  Future<List<AnimalObject>> getAnimalsBySpecies(String species) async {
    final db = await _db;
    try {
      final querySnapshot = await db
          .collection("animals")
          .where("species", isEqualTo: species)
          .orderBy("name")
          .get();

      return querySnapshot.docs.map((doc) {
        return AnimalObject.fromMap(
            doc.data() as Map<String, dynamic>,
            docId: doc.id
        );
      }).toList();
    } catch (e) {
      print("Error getting animals by species: $e");
      return [];
    }
  }

  // Delete animal
  Future<bool> deleteAnimal(String animalId) async {
    final db = await _db;
    try {
      await db.collection("animals").doc(animalId).delete();
      return true;
    } catch (e) {
      print("Error deleting animal: $e");
      return false;
    }
  }

  // LINKING PHOTOS AND ANIMALS

  // Link photo to animal - this both updates the photo and ensures the animal exists
  Future<bool> linkPhotoToAnimal(String photoId, AnimalObject animal) async {
    try {
      // First ensure the animal exists in database
      String? animalId = await saveAnimal(animal);

      if (animalId == null) {
        return false;
      }

      // Then update the photo with the animal ID
      return await classifyPhoto(photoId, animalId);
    } catch (e) {
      print("Error linking photo to animal: $e");
      return false;
    }
  }

  // Get photos with their associated animal data
  Future<List<Map<String, dynamic>>> getPhotosWithAnimalData(String userId) async {
    try {
      // Get all photos for user
      final photos = await getPhotosByUser(userId);
      List<Map<String, dynamic>> result = [];

      // For each photo, get the animal data if it exists
      for (var photo in photos) {
        Map<String, dynamic> photoData = {
          'photo': photo,
          'animal': null
        };

        if (photo.animalClassification != null) {
          final animal = await getAnimalById(photo.animalClassification!);
          if (animal != null) {
            photoData['animal'] = animal;
          }
        }

        result.add(photoData);
      }

      return result;
    } catch (e) {
      print("Error getting photos with animal data: $e");
      return [];
    }
  }

  // Pre-populate animal database with common species
  Future<void> populateAnimalDatabase(List<AnimalObject> animals) async {
    for (var animal in animals) {
      await saveAnimal(animal);
    }
  }
}