import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/entry.dart';
import '../controller/journal_controller.dart';
import '../utils/custom_toast.dart';
import '../utils/mood_utils.dart';
import '../utils/system_ui_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditEntryScreen extends StatefulWidget {
  final Entry entry;
  final JournalController journalController;

  const EditEntryScreen({
    super.key,
    required this.entry,
    required this.journalController,
  });

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  late String? _selectedMood;
  File? _newImageFile;
  bool _hasChanges = false;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.entry.text);
    _selectedMood = widget.entry.mood;
    
    // Listen for changes to track if entry has been modified
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final newHasChanges = _textController.text != widget.entry.text ||
        _selectedMood != widget.entry.mood ||
        _newImageFile != null;
    
    if (newHasChanges != _hasChanges) {
      setState(() {
        _hasChanges = newHasChanges;
      });
    }
  }

  void _onMoodChanged(String? mood) {
    setState(() {
      _selectedMood = mood;
      _hasChanges = _textController.text != widget.entry.text ||
          _selectedMood != widget.entry.mood ||
          _newImageFile != null;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newImageFile = File(image.path);
        _hasChanges = true;
      });
    }
  }

  void _clearNewImage() {
    setState(() {
      _newImageFile = null;
      _hasChanges = _textController.text != widget.entry.text ||
          _selectedMood != widget.entry.mood;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _saveChanges() async {
    if (_isSaving || !_hasChanges) return;

    final trimmedText = _textController.text.trim();
    if (trimmedText.isEmpty && _newImageFile == null && widget.entry.imageUrl == null) {
      CustomToast.show(
        context,
        message: 'Entry cannot be empty',
        icon: Icons.warning_outlined,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.journalController.updateEntry(
        widget.entry,
        text: trimmedText,
        mood: _selectedMood,
        newImageFile: _newImageFile,
      );

      CustomToast.show(
        context,
        message: 'Entry updated successfully',
        icon: Icons.check_circle_outlined,
      );

      Navigator.of(context).pop(true); // Return true to indicate changes were saved
    } catch (e) {
      CustomToast.show(
        context,
        message: 'Failed to update entry',
        icon: Icons.error_outlined,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    updateSystemUiOverlay(context);
    final theme = Theme.of(context);
      return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _onWillPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Entry'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
          ],
        ),
        body: Column(
          children: [
            // Display current/new image if exists
            if (widget.entry.imageUrl != null || _newImageFile != null)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surface,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _newImageFile != null
                          ? Image.file(
                              _newImageFile!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : widget.entry.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.entry.imageUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: theme.colorScheme.surface,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: theme.colorScheme.surface,
                                    child: const Icon(Icons.error),
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          if (_newImageFile != null) {
                            _clearNewImage();
                          } else {
                            // Clear existing image by setting a flag or updating entry
                            _onTextChanged(); // Trigger change detection
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Text input
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mood selector
                    Text(
                      'Mood',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: availableMoods.map((mood) {
                          final isSelected = _selectedMood == mood;
                          return GestureDetector(
                            onTap: () => _onMoodChanged(isSelected ? null : mood),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline,
                                ),
                              ),
                              child: Text(
                                mood,
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Text input
                    Text(
                      'Entry Text',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: 'What\'s on your mind?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom action bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isSaving ? null : _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    tooltip: 'Add image',
                  ),
                  const Spacer(),
                  if (_hasChanges) ...[
                    OutlinedButton(
                      onPressed: _isSaving ? null : () async {
                        if (await _onWillPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
