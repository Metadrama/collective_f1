import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }


  /// Register a new user with email, password, first name, and last name
  Future<UserCredential> signUp(String email, String password, String firstName, String lastName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Save user profile to Firestore
    final user = credential.user;
    if (user != null) {
      final profile = UserProfile(
        uid: user.uid,
        firstName: firstName,
        lastName: lastName,
        email: user.email ?? email,
      );
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(profile.toMap());
      // Optionally update Firebase displayName
      await user.updateDisplayName('$firstName $lastName');
    }
    return credential;
  }

  /// Fetch user profile from Firestore
  Future<UserProfile?> fetchUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data()!);
    }
    return null;
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Stream to listen to auth state (logged in or not)
  Stream<User?> get authState => _auth.authStateChanges();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User canceled
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  /// Sign in with Twitter/X using Firebase OAuthProvider (recommended for Android)
  Future<UserCredential?> signInWithTwitter() async {
    try {
      print('[DEBUG] Starting Twitter sign-in');
      final provider = OAuthProvider('twitter.com');
      // Optionally add custom parameters, e.g. provider.addCustomParameter('lang', 'en');
      final userCredential = await _auth.signInWithProvider(provider);
      print('[DEBUG] Twitter sign-in successful: \\${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[DEBUG] FirebaseAuthException during Twitter sign-in: \\${e.code} - \\${e.message}');
      rethrow;
    } catch (e, stack) {
      print('[DEBUG] Unexpected error during Twitter sign-in: \\${e.toString()}');
      print(stack);
      rethrow;
    }
  }
}

// Global instance
final authManager = AuthManager();
