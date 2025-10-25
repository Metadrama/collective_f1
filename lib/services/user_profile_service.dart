import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'auth_manager.dart';

class UserProfileService extends ChangeNotifier {
  UserProfile? _profile;
  bool _loading = false;

  UserProfile? get profile => _profile;
  bool get loading => _loading;

  Future<void> loadProfile() async {
    _loading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _profile = await authManager.fetchUserProfile(user.uid);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static final instance = UserProfileService();
}
