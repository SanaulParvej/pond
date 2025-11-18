class User {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String name;
  final String? photoUrl;

  const User({
    required this.uid,
    this.email,
    this.phoneNumber,
    required this.name,
    this.photoUrl,
  });

  User copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? name,
    String? photoUrl,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] as String,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      name: map['name'] as String,
      photoUrl: map['photoUrl'] as String?,
    );
  }
}
