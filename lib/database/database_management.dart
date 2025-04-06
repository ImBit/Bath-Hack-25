import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'objects/user_object.dart';
import 'objects/photo_object.dart';

class FirestoreService {
  // Initialize Firebase (only once is better)
  static Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Already initialized
    }
  }

  // Get FirebaseFirestore instance
  static Future<FirebaseFirestore> get _db async {
    await _initializeFirebase();
    return FirebaseFirestore.instance;
  }

// Get user by ID
  static Future<UserObject?> getUserById(String userId) async {
    final db = await _db;
    try {
      final docSnapshot = await db.collection("users").doc(userId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return UserObject.fromMap(data, docId: docSnapshot.id);
      }
      return null;
    } catch (e) {
      print("Error getting user by ID: $e");
      return null;
    }
  }

// Get user by username
  static Future<UserObject?> getUserByUsername(String username) async {
    final db = await _db;
    try {
      final querySnapshot = await db
          .collection("users")
          .where("username", isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return UserObject.fromMap(
            doc.data() as Map<String, dynamic>,
            docId: doc.id
        );
      }
      return null;
    } catch (e) {
      print("Error getting user by username: $e");
      return null;
    }
  }

  static Future<String?> saveUser(UserObject user) async {
    final db = await _db;
    try {
      if (user.id != null && user.id!.isNotEmpty) {
        // First check if the document exists before updating
        final docSnapshot = await db.collection("users").doc(user.id).get();

        if (docSnapshot.exists) {
          await db.collection("users").doc(user.id).update(user.toMap());
          return user.id;
        } else {
          // If document doesn't exist, create it with the provided ID
          await db.collection("users").doc(user.id).set(user.toMap());
          return user.id;
        }
      } else {
        if (!await isUsernameAvailable(user.username)) {
          print("Username already taken");
          return null;
        }
        final docRef = await db.collection("users").add(user.toMap());
        return docRef.id;
      }
    } catch (e) {
      print("Error saving user: $e");
      return null;
    }
  }

  static Future<bool> isUsernameAvailable(String username) async {
    final db = await _db;
    try {
      final querySnapshot = await db
          .collection("users")
          .where("username", isEqualTo: username)
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print("Error checking username availability: $e");
      return false;
    }
  }

  static Future<bool> updateUsername(String userId, String newUsername) async {
    final db = await _db;
    try {
      // First check if the new username is already taken
      if (!await isUsernameAvailable(newUsername)) {
        print("Username already taken");
        return false;
      }

      // Update the username in Firestore
      await db.collection("users").doc(userId).update({
        'username': newUsername
      });
      return true;
    } catch (e) {
      print("Error updating username: $e");
      return false;
    }
  }

  static Future<bool> updateProfilePicture(String userId, String newPfp) async {
    final db = await _db;
    try {
      await db.collection("users").doc(userId).update({
        'pfp': newPfp
      });
      return true;
    } catch (e) {
      print("Error updating profile picture: $e");
      return false;
    }
  }

  static Future<bool> updateBio(String userId, String newBio) async {
    final db = await _db;
    try {
      await db.collection("users").doc(userId).update({
        'bio': newBio
      });
      return true;
    } catch (e) {
      print("Error updating bio: $e");
      return false;
    }
  }

// User login
  static Future<UserObject?> login(String username, String password) async {
    try {
      final user = await getUserByUsername(username);
      if (user == null) {
        print("Username does not exist");
        return null;
      }

      if (user.password == password) {
        return user;
      } else {
        print("Incorrect password");
        return null;
      }
    } catch (e) {
      print("Error during login: $e");
      return null;
    }
  }

  // PHOTO RELATED FUNCTIONS

  // Save or update photo
  static Future<String?> savePhoto(PhotoObject photo) async {
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
  static Future<PhotoObject?> getPhotoById(String photoId) async {
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
  static Future<List<PhotoObject>> getPhotosByUser(String userId) async {
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
  static Future<List<PhotoObject>> getPhotosByAnimal(String animalClassification) async {
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
  static Future<bool> deletePhoto(String photoId) async {
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
  static Future<bool> classifyPhoto(String photoId, String animalClassificationId) async {
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
  static Future<String?> saveAnimal(AnimalObject animal) async {
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
  static Future<AnimalObject?> getAnimalById(String animalId) async {
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
  static Future<AnimalObject?> getAnimalByName(String name) async {
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
  static Future<List<AnimalObject>> getAllAnimals() async {
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
  static Future<List<AnimalObject>> getAnimalsBySpecies(String species) async {
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
  static Future<bool> deleteAnimal(String animalId) async {
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
  static Future<bool> linkPhotoToAnimal(String photoId, AnimalObject animal) async {
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
  static Future<List<Map<String, dynamic>>> getPhotosWithAnimalData(String userId) async {
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
  static Future<void> populateAnimalDatabase(List<AnimalObject> animals) async {
    for (var animal in animals) {
      await saveAnimal(animal);
    }
  }
}