import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../../services/image_encryptor.dart';

class UserObject {
  String? id;
  final String username;
  final String password;
  String bio;
  String pfp;

  UserObject({
    required this.id,
    required this.username,
    required this.password,
    this.bio = "--empty bio--",
    this.pfp = "--pfp--",
  });

  // Convert UserObject to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'bio': bio,
      'pfp': pfp,
    };
  }

  // Create UserObject from Firestore data
  factory UserObject.fromMap(Map<String, dynamic> map, {String? docId}) {
    return UserObject(
      id: docId,
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      bio: map['bio'] ?? '--empty bio--',
      pfp: map['pfp'] ?? '--pfp--',
    );
  }

  @override
  String toString() {
    return 'UserObject(id: $id, username: $username, password: $password, bio: $bio, pfp: $pfp)';
  }
}

extension UserObjectExtension on UserObject {
  Future<void> setProfilePicture(File imageFile) async {
    pfp = await ImageEncryptor.encryptPngToString(imageFile);
  }

  ImageProvider getProfilePictureImage() {
    return ImageEncryptor.createImageFromEncryptedString(pfp);
  }
}