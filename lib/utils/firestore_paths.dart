import 'package:firebase_auth/firebase_auth.dart';

class FirestorePaths {
  static String userEntriesPath() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');
    return 'users/${user.uid}/entries';
  }
}
