import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../controller/journal_controller.dart';
import '../utils/mood_utils.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'custom_image_viewer.dart';
import 'tag_input.dart';

class JournalInputWidget extends StatefulWidget {
  final JournalController journalController;

  const JournalInputWidget({super.key, required this.journalController});

  @override
  State<JournalInputWidget> createState() => _JournalInputWidgetState();
}

class _JournalInputWidgetState extends State<JournalInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _emojiBarController;  bool _isEmojiBarExpanded = false;  // File? _pickedImageFile; // Removed, will use widget.journalController.pickedImageFile
  // final ImagePicker _picker = ImagePicker(); // Removed, logic in JournalController
  bool _isRecording = false;
  
  // Text height tracking for scroll detection
  bool _needsScrolling = false;
  final GlobalKey _textFieldKey = GlobalKey();
  
  // Camera related variables
  CameraController? _cameraController;
  bool _showCameraPreview = false;
  bool _isCameraInitialized = false;
  bool _isVideoRecording = false;  Timer? _recordingTimer;
  File? _generatedGif;
  
  // Gesture detection for tap vs hold
  Timer? _holdTimer;
  bool _isHolding = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _emojiBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
      // Set up callback to clear GIF when image is picked
    widget.journalController.onClearGif = () {
      if (mounted) {
        setState(() {
          _generatedGif = null;
        });
      }
    };
    
    // Listen to controller changes to clear GIF when entry is saved/cleared
    widget.journalController.controller.addListener(_onControllerChanged);
  }  @override
  void dispose() {
    _emojiBarController.dispose();
    _cameraController?.dispose();
    _recordingTimer?.cancel();
    _holdTimer?.cancel();
    widget.journalController.controller.removeListener(_onControllerChanged);
    super.dispose();
  }
  void _onControllerChanged() {
    // Check if content needs scrolling
    _checkIfNeedsScrolling();
    
    // If controller text is cleared (after save), also clear GIF
    if (widget.journalController.controller.text.isEmpty && 
        widget.journalController.pickedGifFile == null && 
        _generatedGif != null) {
      setState(() {
        _generatedGif = null;
      });
    }
  }

  void _checkIfNeedsScrolling() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_textFieldKey.currentContext != null) {
        final RenderBox? renderBox = _textFieldKey.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          // Calculate if the text content exceeds a reasonable height (about 4-5 lines)
          const double maxHeightBeforeScroll = 120.0; // Adjust based on your design
          final bool needsScrolling = renderBox.size.height > maxHeightBeforeScroll;
          
          if (needsScrolling != _needsScrolling) {
            setState(() {
              _needsScrolling = needsScrolling;
            });
          }
        }
      }
    });
  }
  void _showImageViewer(BuildContext context, File imageFile) {
    final imageProvider = FileImage(imageFile);
    final heroTag = 'input_image_${imageFile.path.hashCode}';
    showCustomImageViewer(
      context, 
      imageProvider,
      heroTag: heroTag,
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.low,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }
  void _startRecording() async {
    setState(() {
      _isRecording = true;
    });
    
    // Wait for button to finish ascending (150ms)
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (_isRecording) {
      // Initialize camera if not already done
      if (_cameraController == null) {
        await _initializeCamera();
      }
      
      if (_isCameraInitialized && mounted) {
        setState(() {
          _showCameraPreview = true;
        });
        
        // Start video recording
        await _startVideoRecording();
      }
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.startVideoRecording();
        
        setState(() {
          _isVideoRecording = true;
        });
        
        // Auto-stop recording after 5 seconds (configurable between 3-7s)
        _recordingTimer = Timer(const Duration(seconds: 5), () {
          _stopRecording();
        });
      }
    } catch (e) {
      print('Error starting video recording: $e');
      _stopRecording();
    }
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    
    if (_isVideoRecording && _cameraController != null) {
      try {        final XFile videoFile = await _cameraController!.stopVideoRecording();
        // Convert video to GIF using ffmpeg_kit_flutter_new
        await _convertVideoToGif(videoFile);
        
      } catch (e) {
        print('Error stopping video recording: $e');
      }
    }
    
    setState(() {
      _isRecording = false;
      _showCameraPreview = false;
      _isVideoRecording = false;
    });
    
    //dispose camera usage
    _cameraController?.dispose();
    _cameraController = null;
  }
  Future<void> _convertVideoToGif(XFile videoFile) async {
    try {
      // Get temporary directory for GIF storage
      final Directory tempDir = await getTemporaryDirectory();
      final String gifPath = path.join(
        tempDir.path,
        'journal_gif_${DateTime.now().millisecondsSinceEpoch}.gif',
      );
      
      // FFmpeg command to convert video to GIF
      // Scale to 320px width, optimize for file size, and set frame rate to 10fps
      final String command = '-i "${videoFile.path}" -vf "scale=320:-1:flags=lanczos,fps=10" -loop 0 "$gifPath"';
      
      print('Starting GIF conversion...');
      
      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        
        if (ReturnCode.isSuccess(returnCode)) {
          print('GIF conversion successful: $gifPath');
          
          final File gifFile = File(gifPath);          if (await gifFile.exists()) {
            setState(() {
              _generatedGif = gifFile;
              // Clear any selected image since only one media type is allowed
              widget.journalController.clearImage();
              // Set the GIF in the controller so it gets saved
              widget.journalController.setGifFile(gifFile);
            });
            print('GIF file size: ${await gifFile.length()} bytes');
          }
        } else {
          print('GIF conversion failed with return code: $returnCode');
        }
      });
      
    } catch (e) {
      print('Error converting video to GIF: $e');
    }
  }

  // Method to open camera for photo capture (single tap)
  Future<void> _openCameraForPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Good balance of quality and file size
      );
      
      if (photo != null) {
        final File imageFile = File(photo.path);
        widget.journalController.pickedImageFile = imageFile;
        // Clear any existing GIF since only one media type is allowed
        widget.journalController.pickedGifFile = null;
        widget.journalController.onClearGif?.call();
        widget.journalController.onUpdate();
      }
    } catch (e) {
      print('Error opening camera for photo: $e');
    }
  }

  // Gesture handlers for tap vs hold detection
  void _onTapDown() {
    _isHolding = false;
    _holdTimer = Timer(const Duration(milliseconds: 500), () {
      // If we reach here, it's a hold gesture - start recording
      _isHolding = true;
      _startRecording();
    });
  }

  void _onTapUp() {
    _holdTimer?.cancel();
    
    if (!_isHolding) {
      // It was a quick tap - open camera for photo
      _openCameraForPhoto();
    } else {
      // It was a hold - stop recording
      _stopRecording();
    }
  }

  void _onTapCancel() {
    _holdTimer?.cancel();
    if (_isHolding) {
      _stopRecording();
    }
  }

  // Future<void> _pickImage() async { // Moved to JournalController
  //   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  //   if (image != null) {
  //     setState(() {
  //       _pickedImageFile = File(image.path);
  //     });
  //   }
  // }

  // void _clearImage() { // Moved to JournalController
  //   setState(() {
  //     _pickedImageFile = null;
  //   });
  // }

  void _toggleEmojiBar() {
    setState(() {
      _isEmojiBarExpanded = !_isEmojiBarExpanded;
      if (_isEmojiBarExpanded) {
        _emojiBarController.forward();
      } else {
        _emojiBarController.reverse();
      }
    });  }

  String _getHintText() {
    return "something on your mind?";
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);final fadeValue = (1 +
            (widget.journalController.dragOffsetY /
                JournalController.swipeThreshold))
        .clamp(0.0, 1.0);
    final scaleValue = (1 -
            (widget.journalController.dragOffsetY.abs() /
                (JournalController.swipeThreshold * 1.5)))
        .clamp(0.8, 1.0);

    final bool isSaving = widget.journalController.isSavingEntry;

    return IgnorePointer(
      // Ignore all pointer events if saving
      ignoring: isSaving,
      child: AnimatedOpacity(
        // Wrap with AnimatedOpacity
        duration: const Duration(milliseconds: 200),        opacity: isSaving ? 0.5 : 1.0, // Grey out if saving
        child: Transform.translate(
          offset: Offset(0, _needsScrolling ? 0 : widget.journalController.dragOffsetY),
          child: Transform.scale(
            scale: scaleValue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 5, 0), // Remove left padding to eliminate gap
                  child: Opacity(
                    // This opacity is for the drag fade effect
                    opacity: fadeValue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 1),
                        Stack(
                          alignment: Alignment.center,
                          children: [                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [                                // Emoji/Mood button - no padding, controlled by SizedBox
                                IconButton(
                                  icon:
                                      widget.journalController.selectedMood !=
                                              null
                                          ? Text(
                                            widget
                                                .journalController
                                                .selectedMood!,
                                            style: const TextStyle(
                                              fontSize: 16, // Consistent size
                                            ),
                                          )
                                          : Icon(
                                            Icons.mood,
                                            size: 18, // Consistent icon size
                                            color: theme.iconTheme.color
                                                ?.withOpacity(
                                                  0.7,
                                                ), // Consistent color
                                          ),                                  onPressed: _toggleEmojiBar,
                                  padding: EdgeInsets.zero, // No internal padding
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  visualDensity: VisualDensity.compact,                                ),
                                const SizedBox(width: 4), // Reduced spacing between emoji and add media
                                // Add media button
                                IconButton(
                                  icon: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 18, // Consistent icon size
                                    color: theme.iconTheme.color?.withOpacity(
                                      0.7,
                                    ), // Consistent color
                                  ),
                                  onPressed: widget.journalController.pickImage,
                                  padding: EdgeInsets.zero, // No internal padding
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),                                  visualDensity: VisualDensity.compact,                                ),
                                const SizedBox(width: 4), // Reduced spacing between add media and camera
                                // Camera button for recording
                                GestureDetector(
                                  onTapDown: (details) {
                                    _onTapDown();
                                  },
                                  onTapUp: (details) {
                                    _onTapUp();
                                  },
                                  onTapCancel: () {
                                    _onTapCancel();
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [                                      Container(
                                        padding: EdgeInsets.zero, // No internal padding for consistency
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        alignment: Alignment.center,                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 18, // Consistent with other icons
                                          color: _isRecording
                                              ? Colors.red.withOpacity(0.7)
                                              : theme.iconTheme.color?.withOpacity(0.6), // Slightly softer than others
                                        ),
                                      ),                                      // Camera preview positioned above the button
                                      if (_showCameraPreview && _isCameraInitialized && _cameraController != null)
                                        Positioned(
                                          bottom: 60, // Lifted higher to avoid finger interference
                                          left: -50, // Adjust positioning for new location
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Circular progress bar
                                              SizedBox(
                                                width: 130,
                                                height: 130,
                                                child: TweenAnimationBuilder<double>(
                                                  duration: const Duration(seconds: 5),
                                                  tween: Tween(begin: 0.0, end: _isRecording ? 1.0 : 0.0),
                                                  builder: (context, value, child) {
                                                    return CircularProgressIndicator(
                                                      value: value,
                                                      strokeWidth: 4,
                                                      backgroundColor: Colors.red.withOpacity(0.3),
                                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                                                    );
                                                  },
                                                ),                                              ),
                                              // Camera preview
                                              Container(
                                                width: 120,
                                                height: 120,
                                                child: ClipOval(
                                                  child: CameraPreview(_cameraController!),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),const Spacer(),                                // Save button - always visible
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      widget.journalController.triggerSave();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Save',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),                                ),                            ],
                          ),
                        ],
                        ),
                        const SizedBox(height: 8), // Standardized spacing
                        Row(
                                  children: [                                    Expanded(
                                      child: ConstrainedBox(                                        constraints: BoxConstraints(
                                          maxHeight: _needsScrolling 
                                              ? () {
                                                  final screenHeight = MediaQuery.of(context).size.height;
                                                  final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                                                  final topPadding = MediaQuery.of(context).padding.top;
                                                  final bottomPadding = MediaQuery.of(context).padding.bottom;
                                                  
                                                  // Calculate available height more conservatively
                                                  final availableHeight = screenHeight - keyboardHeight - topPadding - bottomPadding;
                                                  
                                                  // Reserve space for toolbar, margins, and other UI elements (reduced to 150px)
                                                  final reservedSpace = 150.0;
                                                  final usableHeight = availableHeight - reservedSpace;
                                                  
                                                  // Use 50% of usable height for better balance
                                                  return (usableHeight * 0.5).clamp(200.0, 450.0);
                                                }()
                                              : double.infinity, // Balanced height with proper keyboard handling
                                        ),
                                        child: SingleChildScrollView(
                                          child: TextField(
                                            key: _textFieldKey,
                                            cursorColor: theme.brightness == Brightness.dark
                                                ? Colors.white70
                                                : Colors.black54,
                                            controller: widget.journalController.controller,
                                            focusNode: widget.journalController.focusNode,
                                            enabled: !isSaving,
                                            maxLines: null,
                                            scrollPadding: EdgeInsets.zero,
                                            style: theme.textTheme.bodyMedium,
                                            decoration: InputDecoration(
                                              hintText: isSaving ? "Saving entry..." : _getHintText(),
                                              hintStyle: TextStyle(color: theme.hintColor),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                              isDense: true,                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        if (widget.journalController.pickedImageFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 100,
                                    maxWidth: 150,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                      width: 0.5,
                                    ),
                                  ),                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3.5),
                                    child: GestureDetector(
                                      onTap: () => _showImageViewer(context, widget.journalController.pickedImageFile!),
                                      child: Hero(
                                        tag: 'input_image_${widget.journalController.pickedImageFile!.path.hashCode}',
                                        child: Image.file(
                                          widget.journalController.pickedImageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap:
                                      widget
                                          .journalController
                                          .clearImage, // Individual disabling handled by IgnorePointer
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(128),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),                          ),
                        // GIF preview (similar to image preview)
                        if (_generatedGif != null && widget.journalController.pickedImageFile == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 100,
                                    maxWidth: 150,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                      width: 0.5,
                                    ),
                                  ),                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3.5),
                                    child: GestureDetector(
                                      onTap: () => _showImageViewer(context, _generatedGif!),
                                      child: Hero(
                                        tag: 'input_image_${_generatedGif!.path.hashCode}',
                                        child: Image.file(
                                          _generatedGif!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _generatedGif = null;
                                    });
                                    // Also clear from controller
                                    widget.journalController.clearGif();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(128),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: _isEmojiBarExpanded ? 33 : 0,
                  margin: const EdgeInsets.only(top: 4),
                  child: ClipRect(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Row(
                        children:
                            availableMoods.map((emoji) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  // Individual disabling handled by IgnorePointer
                                  widget.journalController.selectedMood = emoji;
                                  _toggleEmojiBar();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    emoji,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color:
                                          widget
                                                      .journalController
                                                      .selectedMood ==
                                                  emoji
                                              ? theme.textTheme.bodyLarge?.color
                                              : theme.textTheme.bodyLarge?.color
                                                  ?.withAlpha(
                                                    (0.8 * 255).round(),
                                                  ),
                                    ),
                                  ),
                                ),
                              );                            }).toList(),
                      ),
                    ),
                  ),
                ),
                // Tag input widget - add at the bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 8, 5, 0),
                  child: TagInputWidget(
                    journalController: widget.journalController,
                    onTagsChanged: (tags) {
                      widget.journalController.updateManualTags(tags);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
