import 'dart:async';
import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:image_picker/image_picker.dart'; // Added for ImagePicker

import 'package:fuzzy/fuzzy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast/sembast_io.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/entry.dart';

import '../utils/date_formatter.dart';
import '../utils/firestore_paths.dart';
import '../utils/animation_utils.dart';

enum SyncStatus { offline, syncing, synced, error }

class JournalController {
  final List<Entry> entries = [];
  final List<Entry> selectedEntries = [];
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController;
  Function()? shouldDisableDrag;
  Function()? onClearGif; // Add callback for clearing GIF widget state

  final TickerProvider vsync;
  final VoidCallback onUpdate;

  double dragOffsetY = 0.0;
  String? selectedMood;
  bool isDragging = false;
  bool hasTriggeredSave = false;
  bool showRipple = false;
  bool isLoading = false;  bool isSavingEntry = false;
  File? pickedImageFile;
  File? pickedGifFile; // Add GIF file support
  final ImagePicker _picker = ImagePicker(); // Added ImagePicker instance
  String _searchTerm = '';
  List<String> manualTags = []; // Add manual tags support
  static const double swipeThreshold = 80.0; // Add swipe threshold constant

  late final AnimationController snapBackController;
  late final AnimationController handlePulseController;

  sembast.Database? _db;
  sembast.StoreRef<String, Map<String, Object?>>? _store;
  SyncStatus _syncStatus = SyncStatus.synced;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  SyncStatus get syncStatus => _syncStatus;

  bool get isSelectionMode => selectedEntries.isNotEmpty;

  List<Entry> get filteredEntries {
    if (_searchTerm.isEmpty) {
      return List<Entry>.from(
        entries,
      ); // Return a copy to avoid direct modification
    }
    final fuse = Fuzzy(
      entries,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'text',
            getter: (entry) => (entry as Entry).text,
            weight: 0.7,
          ),
          WeightedKey(
            name: 'tags',
            getter:
                (entry) => (entry as Entry).tags.join(
                  ' ',
                ), // Join tags into a single string
            weight: 0.3,
          ),
        ],
        threshold: 0.6, // Adjust threshold as needed
      ),
    );
    final results = fuse.search(_searchTerm);
    return results.map((r) => r.item as Entry).toList();
  }

  // Getter for favorite entries
  List<Entry> get favoriteEntries {
    return entries.where((entry) => entry.isFavorite).toList();
  }

  Map<String, List<Entry>> groupEntriesByDate(List<Entry> entriesToGroup) {
    final Map<String, List<Entry>> map = {};
    for (var e in entriesToGroup) {
      final dateStr = DateFormatter.formatForGrouping(e.rawDateTime);
      map.putIfAbsent(dateStr, () => []).add(e);
    }
    return map;
  }

  void updateSearchTerm(String term) {
    _searchTerm = term;
    onUpdate();
  }

  // Manual tagging methods
  void updateManualTags(List<String> tags) {
    manualTags = List.from(tags);
    onUpdate();
  }

  void addManualTag(String tag) {
    if (!manualTags.contains(tag)) {
      manualTags.add(tag);
      onUpdate();
    }
  }

  void removeManualTag(String tag) {
    manualTags.remove(tag);
    onUpdate();
  }

  void clearManualTags() {
    manualTags.clear();
    onUpdate();
  }

  JournalController({
    required this.vsync,
    required this.onUpdate,
    required this.scrollController,
  }) {
    snapBackController = AnimationUtils.createSnapBackController(vsync)
      ..addListener(() {
        dragOffsetY = snapBackController.value * 0;
        onUpdate();
      });

    handlePulseController = AnimationUtils.createPulseController(vsync)
      ..repeat(reverse: true);

    _initDb();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );
  }

  Future<void> _initDb() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDocDir.path}/journal.db';
    _db = await databaseFactoryIo.openDatabase(dbPath);
    _store = sembast.stringMapStoreFactory.store('entries');
    await loadEntries(); // Load entries after DB init
  }

  Future<void> _updateConnectivityStatus(ConnectivityResult result) async {
    // Always update sync status instantly on connectivity change
    if (result == ConnectivityResult.none) {
      _syncStatus = SyncStatus.offline;
      onUpdate();
      return;
    }
    // If we came online from an offline/error state, try to sync.
    if (_syncStatus == SyncStatus.offline || _syncStatus == SyncStatus.error) {
      await _syncOfflineEntries();
    }
    // Update status based on pending items regardless of immediate sync outcome
    _updateSyncStatus(); // Ensures status reflects current DB state
  }

  void _updateSyncStatus() {
    Connectivity().checkConnectivity().then((connectivityResult) {
      if (connectivityResult == ConnectivityResult.none) {
        _syncStatus = SyncStatus.offline;
        onUpdate();
        return;
      }
      if (_store != null && _db != null) {
        _store!
            .query(
              finder: sembast.Finder(
                filter: sembast.Filter.equals('isSynced', false),
              ),
            )
            .count(_db!)
            .then((count) {
              if (count > 0) {
                _syncStatus = SyncStatus.syncing;
              } else {
                _syncStatus = SyncStatus.synced;
              }
              onUpdate();
            });
      } else {
        _syncStatus = SyncStatus.synced;
        onUpdate();
      }
    });
  }

  Future<void> loadEntries() async {
    isLoading = true;
    onUpdate();

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _syncStatus = SyncStatus.offline;
      await _loadEntriesFromDb();
    } else {
      _syncStatus = SyncStatus.synced;
      await loadEntriesFromFirestore();
    }
    isLoading = false;
    onUpdate();
  }

  Future<void> _loadEntriesFromDb() async {
    if (_db == null || _store == null) return;
    final records = await _store!.find(_db!);
    entries.clear();
    for (var record in records) {
      entries.add(_entryFromMap(record.key, record.value));
    }
    entries.sort((a, b) => b.rawDateTime.compareTo(a.rawDateTime)); // Sort newest first
    onUpdate();
  }

  Future<void> loadEntriesFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isLoading = false;
      onUpdate();
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection(FirestorePaths.userEntriesPath())
              .orderBy('timestamp', descending: false)
              .get();

      final loadedEntries =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final parsedTimestamp = DateTime.parse(data['timestamp']);
            return Entry(
              firestoreId: doc.id,
              text: data['text'] ?? '',
              timestamp: DateFormatter.formatTime(parsedTimestamp),
              rawDateTime: parsedTimestamp,
              animController: AnimationUtils.createDefaultController(vsync)
                ..forward(),
              mood: data['mood'],
              tags: List<String>.from(data['tags'] ?? []),
              wordCount: data['wordCount'] ?? 0,
              imageUrl: data['imageUrl'] as String?,
              isFavorite: data['isFavorite'] ?? false,
              isSynced: true,
              localId: doc.id,
              localImagePath: null,
            );
          }).toList();      entries.clear();
      entries.addAll(loadedEntries);
      // Sort entries newest first
      entries.sort((a, b) => b.rawDateTime.compareTo(a.rawDateTime));

      if (_db != null && _store != null) {
        await _store!.delete(_db!);
        for (var entry in entries) {
          await _store!
              .record(entry.firestoreId!)
              .put(_db!, _entryToMap(entry));
        }
      }
      _syncStatus = SyncStatus.synced;
    } catch (e) {
      debugPrint("Error loading from Firestore: $e");
      _syncStatus = SyncStatus.error;
      await _loadEntriesFromDb();
    }

    isLoading = false;
    onUpdate();
  }

  Future<void> _saveEntry() async {
    if (isSavingEntry) return;

    isSavingEntry = true;
    _syncStatus = SyncStatus.syncing;
    onUpdate();    final text = controller.text.trim();
    if (text.isEmpty && pickedImageFile == null && pickedGifFile == null) {
      isSavingEntry = false;
      _updateSyncStatus();
      onUpdate();
      return;
    }

    final animationController = AnimationUtils.createDefaultController(vsync);
    String? uploadedImageUrl;
    String? localImagePath;
    final user = FirebaseAuth.instance.currentUser;
    final timestamp = DateTime.now();
    final localId =
        'local_${timestamp.millisecondsSinceEpoch}_${entries.length}';    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none;

    // Handle image upload
    if (pickedImageFile != null) {
      if (isOnline && user != null) {
        try {
          final fileName =
              '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child(user.uid)
              .child(fileName);
          UploadTask uploadTask = storageRef.putFile(pickedImageFile!);
          TaskSnapshot snapshot = await uploadTask;
          uploadedImageUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          debugPrint("Error uploading image: $e");
        }
      } else {
        // Offline: store local image path
        localImagePath = pickedImageFile!.path;
      }
    }    // Handle GIF upload
    if (pickedGifFile != null) {
      if (isOnline && user != null) {
        try {
          debugPrint("Uploading GIF for user: ${user.uid}");
          final fileName =
              '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.gif';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_gifs')
              .child(user.uid)
              .child(fileName);
          debugPrint("Storage path: ${storageRef.fullPath}");
          UploadTask uploadTask = storageRef.putFile(pickedGifFile!);
          TaskSnapshot snapshot = await uploadTask;
          uploadedImageUrl = await snapshot.ref.getDownloadURL(); // Use same field for both
          debugPrint("GIF uploaded successfully: $uploadedImageUrl");
        } catch (e) {
          debugPrint("Error uploading GIF: $e");
          // If upload fails, store locally for offline sync
          localImagePath = pickedGifFile!.path;
        }
      } else {
        // Offline: store local GIF path
        localImagePath = pickedGifFile!.path;
        debugPrint("Storing GIF locally (offline): $localImagePath");
      }
    }    final mood = selectedMood;
    // Use manual tags instead of automatic extraction
    final List<String> tags = List<String>.from(manualTags);
    final wordCount =
        text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;

    final entry = Entry(
      localId: localId,
      text: text,
      timestamp: DateFormatter.formatTime(timestamp),
      rawDateTime: timestamp,
      animController: animationController,
      mood: mood,
      tags: tags,
      wordCount: wordCount,
      imageUrl: uploadedImageUrl,
      isSynced: false,
      firestoreId: null,
      localImagePath: localImagePath, // Save local image path if offline
    );    entries.add(entry);
    // Sort entries to ensure newest first
    entries.sort((a, b) => b.rawDateTime.compareTo(a.rawDateTime));
    if (_db != null && _store != null) {
      await _store!.record(localId).put(_db!, _entryToMap(entry));
    }    controller.clear();
    pickedImageFile = null;
    pickedGifFile = null; // Clear GIF file too
    onClearGif?.call(); // Explicitly clear GIF widget state
    dragOffsetY = 0;
    selectedMood = null;
    manualTags.clear(); // Clear manual tags after saving
    showRipple = true;
    animationController.forward();
    
    // Update UI immediately to show the new entry
    onUpdate();WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0, // Scroll to top for newest entries
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    if (isOnline && user != null) {
      try {
        final firestoreData = _entryToFirestoreMap(entry);
        final docRef = await FirebaseFirestore.instance
            .collection(FirestorePaths.userEntriesPath())
            .add(firestoreData);        entry.firestoreId = docRef.id;
        entry.isSynced = true;
        if (_db != null && _store != null) {
          await _store!.record(localId).update(_db!, {
            'firestoreId': docRef.id,
            'isSynced': true,
          });
        }
        _syncStatus = SyncStatus.synced;
        // Additional update after Firestore sync
        onUpdate();
      } catch (e) {
        debugPrint("Error saving to Firestore: $e");
        entry.isSynced = false;
        _syncStatus = SyncStatus.error;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      showRipple = false;
      isSavingEntry = false;
      _updateSyncStatus();
      onUpdate();
    });
  }

  Future<void> _syncOfflineEntries() async {
    if (_db == null || _store == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _syncStatus = SyncStatus.offline;
      onUpdate();
      return;
    }

    _syncStatus = SyncStatus.syncing;
    onUpdate();

    final recordsToSync = await _store!
        .query(
          finder: sembast.Finder(
            filter: sembast.Filter.equals('isSynced', false),
          ),
        )
        .getSnapshots(_db!);

    for (var recordSnapshot in recordsToSync) {
      final entryData = recordSnapshot.value;
      final localId = recordSnapshot.key;
      Entry entry = _entryFromMap(localId, entryData);

      // If entry has a local image path but no imageUrl, upload the image
      if (entry.localImagePath != null &&
          entry.localImagePath!.isNotEmpty && // Added check for empty path
          (entry.imageUrl == null || entry.imageUrl!.isEmpty)) {        try {
          final file = File(entry.localImagePath!);
          if (await file.exists()) { // Check if file exists before upload
            final isGif = entry.localImagePath!.toLowerCase().endsWith('.gif');
            final fileName = isGif
                ? '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.gif'
                : '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final storageRef = FirebaseStorage.instance
                .ref()
                .child(isGif ? 'user_gifs' : 'user_images')
                .child(user.uid)
                .child(fileName);
            UploadTask uploadTask = storageRef.putFile(file);
            TaskSnapshot snapshot = await uploadTask;
            final url = await snapshot.ref.getDownloadURL();
            entry.imageUrl = url;
            entry.localImagePath = null; // Clear local path after successful upload
          } else {
            debugPrint("Offline file not found: ${entry.localImagePath}");
            // Decide how to handle missing file: clear localImagePath? Mark as error?
            entry.localImagePath = null; // Example: clear it to prevent re-attempts
          }        } catch (e) {
          debugPrint("Error uploading offline file for entry $localId: $e");
        }
      }

      try {
        final firestoreData = _entryToFirestoreMap(entry);
        DocumentReference docRef;
        if (entry.firestoreId != null) {
          docRef = FirebaseFirestore.instance
              .collection(FirestorePaths.userEntriesPath())
              .doc(entry.firestoreId);
          await docRef.set(firestoreData, SetOptions(merge: true));
        } else {
          docRef = await FirebaseFirestore.instance
              .collection(FirestorePaths.userEntriesPath())
              .add(firestoreData);
          entry.firestoreId = docRef.id;
        }

        entry.isSynced = true;

        await _store!.record(localId).update(_db!, {
          'isSynced': true,
          'firestoreId': entry.firestoreId,
          'imageUrl': entry.imageUrl,
          'localImagePath': entry.localImagePath,
        });

        final index = entries.indexWhere((e) => e.localId == localId);
        if (index != -1) {
          entries[index] = entry;
        }
      } catch (e) {
        debugPrint("Error syncing entry $localId to Firestore: $e");
        _syncStatus = SyncStatus.error;
        onUpdate();
      }
    }
    _updateSyncStatus();
  }

  Map<String, Object?> _entryToMap(Entry entry) {
    return {
      'localId': entry.localId,
      'firestoreId': entry.firestoreId,
      'text': entry.text,
      'timestamp': entry.rawDateTime.toIso8601String(),
      'mood': entry.mood,
      'tags': entry.tags,
      'wordCount': entry.wordCount,
      'imageUrl': entry.imageUrl,
      'isFavorite': entry.isFavorite,
      'isSynced': entry.isSynced,
      'localImagePath': entry.localImagePath,
      // animController is not stored in the database
    };
  }

  Entry _entryFromMap(String localId, Map<String, dynamic> data) {
    final rawDateTime = DateTime.parse(data['timestamp'] as String);
    return Entry(
      localId: localId,
      firestoreId: data['firestoreId'] as String?,
      text: data['text'] as String,
      timestamp: DateFormatter.formatTime(rawDateTime),
      rawDateTime: rawDateTime,
      animController: AnimationUtils.createDefaultController(vsync)..forward(), // Created on load
      mood: data['mood'] as String?,
      tags: List<String>.from(data['tags'] as List? ?? []),
      wordCount: data['wordCount'] as int? ?? 0,
      imageUrl: data['imageUrl'] as String?,
      isFavorite: data['isFavorite'] as bool? ?? false,
      isSynced: data['isSynced'] as bool? ?? true, // Default to true, will be accurate after sync
      localImagePath: data['localImagePath'] as String?,
    );
  }

  Map<String, dynamic> _entryToFirestoreMap(Entry entry) {
    return {
      'text': entry.text,
      'timestamp': entry.rawDateTime.toIso8601String(),
      'mood': entry.mood,
      'tags': entry.tags,
      'wordCount': entry.wordCount,
      'imageUrl': entry.imageUrl,
      'isFavorite': entry.isFavorite,
      // localId, isSynced, localImagePath are not part of the Firestore document map directly
    };
  }

  Future<void> deleteSelectedEntries() async {
    if (_db == null || _store == null) return;

    final List<String?> nullableLocalIdsToDelete = selectedEntries.map((e) => e.localId).toList();
    final List<String> localIdsToDelete = nullableLocalIdsToDelete.whereType<String>().toList();

    if (localIdsToDelete.isEmpty && selectedEntries.any((e) => e.firestoreId == null)) {
        // Handle cases where entries might only exist in memory before being saved
        // or if localId was unexpectedly null for a selected entry.
        selectedEntries.clear();
        onUpdate();
        return;
    }

    for (var entry in selectedEntries) {
      if (entry.firestoreId != null) {
        FirebaseFirestore.instance
            .collection(FirestorePaths.userEntriesPath())
            .doc(entry.firestoreId)
            .delete()
            .catchError((e) {
          debugPrint("Error deleting entry ${entry.firestoreId} from Firestore: $e");
        });
      }
      if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(entry.imageUrl!).delete();
        } catch (e) {
          debugPrint("Error deleting image ${entry.imageUrl} from Storage: $e");
        }
      }
    }
    if (localIdsToDelete.isNotEmpty) {
      await _store!.records(localIdsToDelete).delete(_db!);
    }
    
    entries.removeWhere((entry) => localIdsToDelete.contains(entry.localId) || selectedEntries.contains(entry));
    selectedEntries.clear();
    onUpdate();
    _updateSyncStatus();
  }

  void dispose() {
    controller.dispose();
    focusNode.dispose();
    snapBackController.dispose();
    handlePulseController.dispose();
    _connectivitySubscription?.cancel();
    for (var entry in entries) {
      entry.dispose(); // Entry model now has a dispose method
    }
    _db?.close(); // Close the Sembast database
  }
  // Drag handlers
  void handleDragUpdate(DragUpdateDetails details) {
    if (isSavingEntry || controller.text.trim().isEmpty) return;

    // Check if dragging should be disabled due to scrolling text
    if (shouldDisableDrag?.call() == true) return;

    dragOffsetY += details.delta.dy;
    dragOffsetY = dragOffsetY.clamp(-300.0, 0.0);
    isDragging = true;
    onUpdate();

    if (!hasTriggeredSave && dragOffsetY < -swipeThreshold) {
      hasTriggeredSave = true;
      _saveEntry();
      snapBackController.forward(from: 0);
      dragOffsetY = 0;
      isDragging = false;
      onUpdate();
    }
  }

  void handleDragEnd() {
    hasTriggeredSave = false;
    if (!isDragging) return;

    snapBackController.forward(from: 0);
    dragOffsetY = 0;
    isDragging = false;
    onUpdate();
  }

  void toggleEntrySelection(Entry entry) {
    entry.isSelected = !entry.isSelected;
    if (entry.isSelected) {
      selectedEntries.add(entry);
    } else {
      selectedEntries.remove(entry);
    }
    onUpdate();
  }

  void clearSelection() {
    for (var entry in selectedEntries) {
      entry.isSelected = false;
    }
    selectedEntries.clear();
    onUpdate();
  }  void cancelEntry() {
    controller.clear();
    pickedImageFile = null;
    pickedGifFile = null; // Clear GIF file too
    selectedMood = null;
    manualTags.clear(); // Clear manual tags when canceling
    showRipple = false;
    dragOffsetY = 0;
    onClearGif?.call(); // Clear GIF from widget
    onUpdate();
  }

  void triggerSave() {
    if (!hasTriggeredSave) {
      hasTriggeredSave = true;
      _saveEntry();    }
  }

  // Method to pick an image
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      pickedImageFile = File(image.path);
      // Clear any existing GIF since only one media type is allowed
      pickedGifFile = null;
      onClearGif?.call();
      onUpdate();
    }
  }
  // Method to clear the picked image
  void clearImage() {
    pickedImageFile = null;
    onUpdate();
  }

  // Method to set GIF file
  void setGifFile(File gifFile) {
    pickedGifFile = gifFile;
    // Clear any selected image since only one media type is allowed
    pickedImageFile = null;
    onUpdate();
  }
  // Method to clear the GIF file
  void clearGif() {
    pickedGifFile = null;
    onClearGif?.call(); // Also clear widget state
    onUpdate();
  }

  // Method to toggle favorite status
  Future<void> toggleFavorite(Entry entry) async {
    entry.isFavorite = !entry.isFavorite;
    onUpdate(); // Update UI immediately

    try {
      if (_db != null && _store != null && entry.localId != null) { // Added null check for localId
        await _store!.record(entry.localId!).update(_db!, {'isFavorite': entry.isFavorite});
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none && entry.firestoreId != null) {
        await FirebaseFirestore.instance
            .collection(FirestorePaths.userEntriesPath())
            .doc(entry.firestoreId)
            .update({'isFavorite': entry.isFavorite});
      } else if (connectivityResult == ConnectivityResult.none && entry.firestoreId != null) {
        // If offline but has a firestoreId, it means it was synced before.
        // The local DB change is already made. It will sync when back online.
        entry.isSynced = false; // Mark for sync
         if (_db != null && _store != null && entry.localId != null) { // Added null check for localId
          await _store!.record(entry.localId!).update(_db!, {'isSynced': false});
        }
      }
       _updateSyncStatus();
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
      // Optionally revert UI change or show error
      entry.isFavorite = !entry.isFavorite; // Revert
      onUpdate();
    }
  }

  void selectEntriesByDate(List<Entry> entriesInGroup) {
    for (var entry in entriesInGroup) {
      if (!entry.isSelected) {
        entry.isSelected = true;
        selectedEntries.add(entry);
      }
    }
    onUpdate();
  }

  void deselectEntriesByDate(List<Entry> entriesInGroup) {
    for (var entry in entriesInGroup) {
      if (entry.isSelected) {
        entry.isSelected = false;
        selectedEntries.remove(entry);
      }
    }
    onUpdate();
  }

  // Method to update an existing entry
  Future<void> updateEntry(
    Entry entry, {
    required String text,
    String? mood,
    File? newImageFile,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none;    // Use manual tags instead of automatic extraction  
    final tags = List<String>.from(manualTags);
    final wordCount = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

    String? newImageUrl = entry.imageUrl;
    String? newLocalImagePath = entry.localImagePath;

    // Handle new image upload
    if (newImageFile != null) {
      if (isOnline && user != null) {
        try {
          // Delete old image if it exists
          if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
            try {
              await FirebaseStorage.instance.refFromURL(entry.imageUrl!).delete();
            } catch (e) {
              debugPrint("Error deleting old image: $e");
            }
          }

          // Upload new image
          final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child(user.uid)
              .child(fileName);
          
          final uploadTask = storageRef.putFile(newImageFile);
          final snapshot = await uploadTask;
          newImageUrl = await snapshot.ref.getDownloadURL();
          newLocalImagePath = null; // Clear local path since we have URL
        } catch (e) {
          debugPrint("Error uploading new image: $e");
          // If upload fails, save local path for later sync
          newLocalImagePath = newImageFile.path;
        }
      } else {
        // Offline - save local path
        newLocalImagePath = newImageFile.path;
      }
    }

    // Create updated entry data
    final updatedEntryData = {
      'text': text,
      'mood': mood,
      'tags': tags,
      'wordCount': wordCount,
      'imageUrl': newImageUrl,
      'localImagePath': newLocalImagePath,
      'isSynced': false, // Mark as needing sync
    };

    // Update local database
    if (_db != null && _store != null && entry.localId != null) {
      await _store!.record(entry.localId!).update(_db!, updatedEntryData);
    }

    // Update the entry object in memory
    final index = entries.indexWhere((e) => e.localId == entry.localId);
    if (index != -1) {
      // Update entry properties
      final updatedEntry = Entry(
        localId: entry.localId,
        firestoreId: entry.firestoreId,
        text: text,
        timestamp: entry.timestamp,
        rawDateTime: entry.rawDateTime,
        animController: entry.animController,
        mood: mood,
        tags: tags,
        wordCount: wordCount,
        imageUrl: newImageUrl,
        isFavorite: entry.isFavorite,
        isSelected: entry.isSelected,
        isSynced: false,
        localImagePath: newLocalImagePath,
      );
      
      entries[index] = updatedEntry;
    }

    // Update UI immediately
    onUpdate();

    // Sync to Firestore if online
    if (isOnline && user != null && entry.firestoreId != null) {
      try {
        final firestoreData = {
          'text': text,
          'mood': mood,
          'tags': tags,
          'wordCount': wordCount,
          'imageUrl': newImageUrl,
          'isFavorite': entry.isFavorite,
          'timestamp': entry.rawDateTime.toIso8601String(),
        };

        await FirebaseFirestore.instance
            .collection(FirestorePaths.userEntriesPath())
            .doc(entry.firestoreId)
            .update(firestoreData);

        // Mark as synced
        if (_db != null && _store != null && entry.localId != null) {
          await _store!.record(entry.localId!).update(_db!, {'isSynced': true});
        }

        // Update entry sync status in memory
        final updatedIndex = entries.indexWhere((e) => e.localId == entry.localId);
        if (updatedIndex != -1) {
          entries[updatedIndex].isSynced = true;
        }

        _syncStatus = SyncStatus.synced;
      } catch (e) {
        debugPrint("Error updating entry in Firestore: $e");
    _syncStatus = SyncStatus.error;
      }
    } else {
      _syncStatus = SyncStatus.offline;
    }    _updateSyncStatus();
    onUpdate();
  }

  /// Scroll to a specific entry by ID
  Future<void> scrollToEntry(String entryId) async {
    // Find the entry by either localId or firestoreId
    final entryIndex = entries.indexWhere((entry) => 
      entry.localId == entryId || entry.firestoreId == entryId);
    
    if (entryIndex == -1) {
      debugPrint('Entry with ID $entryId not found');
      return;
    }

    // Group entries by date to calculate scroll position
    final grouped = groupEntriesByDate(entries);
    double scrollOffset = 0.0;
    bool foundEntry = false;

    // Calculate approximate scroll position
    for (final group in grouped.entries) {
      if (foundEntry) break;
      
      // Add header height
      scrollOffset += 60.0; // Approximate header height
      
      for (final entry in group.value) {
        if (entry.localId == entryId || entry.firestoreId == entryId) {
          foundEntry = true;
          break;
        }
        // Add approximate entry height (varies by content)
        scrollOffset += 120.0; // Base entry height
        if (entry.text.length > 100) {
          scrollOffset += (entry.text.length / 100) * 20; // Additional height for longer text
        }
        if (entry.imageUrl != null || entry.localImagePath != null) {
          scrollOffset += 200.0; // Additional height for images
        }
      }
    }

    // Animate to the calculated position
    if (scrollController.hasClients) {
      await scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }
}
