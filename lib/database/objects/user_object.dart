import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../../services/image_encryptor.dart';

class UserObject {
  String? id;
  final String username;
  final String password;
  String bio;
  String pfp;
  bool isStaff;

  UserObject({
    required this.id,
    required this.username,
    required this.password,
    this.bio = "--empty bio--",
    this.pfp = "--pfp--",
    this.isStaff = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'bio': bio,
      'pfp': pfp,
      'isStaff': isStaff,
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
      isStaff: map['isStaff'] ?? 'false',
    );
  }

  @override
  String toString() {
    return 'UserObject(id: $id, username: $username, password: $password, bio: $bio, pfp: $pfp, isStaff: $isStaff)';
  }

  bool isUserStaff() {
    return isStaff;
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