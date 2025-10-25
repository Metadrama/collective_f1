import 'package:flutter/animation.dart';

class Entry {
  String? firestoreId; // Changed to non-final to allow update after sync
  final String text;
  final String timestamp; // formatted time only: e.g., "3:42 PM"
  final DateTime rawDateTime; // raw full datetime for grouping
  bool isFavorite;
  final AnimationController animController;
  final String? mood; // Changed to nullable String
  final List<String> tags;
  final int wordCount;
  String? imageUrl; // Added for image URL
  bool isSelected;
  String? localId; // For local DB key before Firestore sync
  bool isSynced; // To track if the entry is synced with Firestore
  String? localImagePath; // For offline image path

  Entry({
    this.firestoreId, // Added to constructor
    required this.text,
    required this.timestamp,
    required this.rawDateTime,
    this.isFavorite = false,
    required this.animController,
    this.mood, // Changed to optional
    required this.tags,
    required this.wordCount,
    this.imageUrl, // Added to constructor
    this.isSelected = false,
    this.localId, // Added to constructor
    this.isSynced = false, // Added to constructor
    this.localImagePath, // Add to constructor
  });

  void dispose() {
    animController.dispose();
  }
}
