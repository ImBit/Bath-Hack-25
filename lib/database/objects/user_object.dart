class UserObject {
  String? id;
  final String username;
  final String password;
  String bio;
  String pfp;

  UserObject({
    this.id,
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