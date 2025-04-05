import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'objects/user_object.dart';

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

  // Get user by ID
  Future<UserObject?> getUserById(String userId) async {
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
  Future<UserObject?> getUserByUsername(String username) async {
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

  // Save or update user
  Future<String?> saveUser(UserObject user) async {
    final db = await _db;
    try {
      if (user.id != null) {
        // Update existing user
        await db.collection("users").doc(user.id).update(user.toMap());
        return user.id;
      } else {
        // Check if username already exists
        if (!await isUsernameAvailable(user.username)) {
          print("Username already taken");
          return null;
        }
        // Create new user
        final docRef = await db.collection("users").add(user.toMap());
        return docRef.id;
      }
    } catch (e) {
      print("Error saving user: $e");
      return null;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
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

  // User login
  Future<String> login(String username, String password) async {
    try {
      final user = await getUserByUsername(username);
      if (user == null) {
        return "Username does not exist";
      }

      if (user.password == password) {
        return "Logged in";
      } else {
        return "Incorrect password";
      }
    } catch (e) {
      print("Error during login: $e");
      return "Login failed";
    }
  }

  // Register user
  Future<String> registerUser(String username, String password) async {
    try {
      if (!await isUsernameAvailable(username)) {
        return "Username already taken";
      }

      final userObj = UserObject(
        username: username,
        password: password,
      );

      final userId = await saveUser(userObj);
      return userId != null
          ? "Registration successful"
          : "Registration failed";
    } catch (e) {
      print("Error during registration: $e");
      return "Registration failed";
    }
  }

  // Get all users
  Future<List<UserObject>> getAllUsers() async {
    final db = await _db;
    try {
      final querySnapshot = await db.collection("users").get();

      return querySnapshot.docs.map((doc) {
        return UserObject.fromMap(
            doc.data() as Map<String, dynamic>,
            docId: doc.id
        );
      }).toList();
    } catch (e) {
      print("Error getting all users: $e");
      return [];
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    final db = await _db;
    try {
      await db.collection("users").doc(userId).delete();
      return true;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }
}