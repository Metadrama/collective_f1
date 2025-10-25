class UserProfile {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;

  UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] ?? '',
        firstName: map['firstName'] ?? '',
        lastName: map['lastName'] ?? '',
        email: map['email'] ?? '',
      );
}
