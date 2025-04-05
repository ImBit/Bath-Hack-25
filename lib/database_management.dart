import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreService {

  void returnUser(userID) async {
    await Firebase.initializeApp();
    FirebaseFirestore db = FirebaseFirestore.instance;

    final user = db.collection("users").doc(userID);
    user.get().then(
      (DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        print(data);
      },
      onError: (e) => print("Error getting document: $e"),
    );
  }


  Future<String> getPassword(username) async {
    await Firebase.initializeApp();
    FirebaseFirestore db = FirebaseFirestore.instance;

    final user = db.collection("users").where("username", isEqualTo: username);
    user.get().then(
      (QuerySnapshot query) {
        for (var docSnapshot in query.docs) {
          final password = docSnapshot.get("password");
          return password;
        }
      },
      onError: (e) => print("Error getting document: $e"),
    );
    return "error";
  }

  void registerUser(username, password) async {
    if (!await validUsername(username)) {
      return;
    }

    await Firebase.initializeApp();
    FirebaseFirestore db = FirebaseFirestore.instance;

    final user = <String, dynamic>{
      "username": username,
      "password": password,
      "bio": "--empty bio--",
      "pfp": "--pfp--"
    };

    db.collection("users").add(user);
  }

  Future<bool> validUsername(username) async {
    await Firebase.initializeApp();
    FirebaseFirestore db = FirebaseFirestore.instance;

    QuerySnapshot snapshot = await db.collection("users").get();

    List<String> usernames = snapshot.docs.map((doc) => doc.get("username") as String).toList();
    if (usernames.contains(username)) {
      return false;
    } else {
      return true;
    }
  }

  Future<String> login(username, password) async {
    await Firebase.initializeApp();
    FirebaseFirestore db = FirebaseFirestore.instance;

    if (await validUsername(username)) {
      return "Username does not exist";
    }

    if (getPassword(username) == password) {
      return "Logged in";
    } else {
      return "Incorrect username";
    }

  }
}
