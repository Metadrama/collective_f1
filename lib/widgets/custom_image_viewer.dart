import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomImageViewer extends StatefulWidget {
  final ImageProvider imageProvider;
  final String? heroTag;

  const CustomImageViewer({
    super.key,
    required this.imageProvider,
    this.heroTag,
  });

  @override
  State<CustomImageViewer> createState() => _CustomImageViewerState();
}

class _CustomImageViewerState extends State<CustomImageViewer>
    with TickerProviderStateMixin {
  late TransformationController _transformationController;  late AnimationController _animationController;
  late AnimationController _dismissController;
  Animation<double>? _animation;
  Animation<Offset>? _dismissAnimation;
  Timer? _hintTimer;
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _panOffset = Offset.zero;
  Offset _previousPanOffset = Offset.zero;
  bool _isDismissing = false;
  double _dismissProgress = 0.0;
  bool _showDismissHint = true;
  bool _isVerticalGesture = false;
  double _gestureStartY = 0.0;
  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _dismissController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Auto-hide hint after 3 seconds
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showDismissHint) {
        setState(() {
          _showDismissHint = false;
        });
      }
    });
  }
  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    _dismissController.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }
  void _onScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _previousPanOffset = _panOffset;
    _animationController.stop();
    
    // Track gesture start for better dismiss detection
    _gestureStartY = details.focalPoint.dy;
    _isVerticalGesture = false;
    
    // Hide hint after first interaction
    if (_showDismissHint) {
      setState(() {
        _showDismissHint = false;
      });
    }
  }
  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Handle scaling with better sensitivity
      if (details.scale != 1.0) {
        _scale = (_previousScale * details.scale).clamp(0.5, 4.0);
      }
      
      // Handle panning
      if (_scale > 1.0) {
        _panOffset = _previousPanOffset + details.focalPointDelta;
        
        // Constrain panning to keep image in bounds
        final screenSize = MediaQuery.of(context).size;
        final maxPanX = (screenSize.width * (_scale - 1)) / 2;
        final maxPanY = (screenSize.height * (_scale - 1)) / 2;
        
        _panOffset = Offset(
          _panOffset.dx.clamp(-maxPanX, maxPanX),
          _panOffset.dy.clamp(-maxPanY, maxPanY),
        );
      } else {
        // Handle vertical swipe for dismiss when not zoomed
        final verticalDelta = details.focalPointDelta.dy;
        final horizontalDelta = details.focalPointDelta.dx;
        
        // Detect if this is primarily a vertical gesture
        if (!_isVerticalGesture && verticalDelta.abs() > horizontalDelta.abs() && verticalDelta.abs() > 10) {
          _isVerticalGesture = true;
        }
        
        if (_isVerticalGesture) {
          final totalVerticalDistance = details.focalPoint.dy - _gestureStartY;
          _dismissProgress = (totalVerticalDistance.abs() / 150).clamp(0.0, 1.0);
          _panOffset = Offset(0, totalVerticalDistance);
        }
      }
    });
  }
  void _onScaleEnd(ScaleEndDetails details) {
    // Handle dismiss gesture - check both distance and velocity
    if (_scale <= 1.0 && _isVerticalGesture) {
      final shouldDismiss = _dismissProgress > 0.3 || // Moved far enough
                           (details.velocity.pixelsPerSecond.dy.abs() > 300 && _dismissProgress > 0.1); // Fast enough
      
      if (shouldDismiss) {
        _startDismiss();
        return;
      }
    }
    
    // Reset dismiss state
    if (_dismissProgress > 0) {
      _animateToPosition(Offset.zero, _scale);
      _dismissProgress = 0.0;
      _isVerticalGesture = false;
    }
    
    // Double tap to zoom
    if (details.pointerCount == 1) {
      if (_scale > 1.5) {
        _animateToPosition(Offset.zero, 1.0);
      }
    }
    
    // Constrain scale
    if (_scale < 1.0) {
      _animateToPosition(Offset.zero, 1.0);
    } else if (_scale > 4.0) {
      _animateToPosition(_panOffset, 4.0);
    }
  }

  void _onDoubleTap() {
    if (_scale > 1.2) {
      _animateToPosition(Offset.zero, 1.0);
    } else {
      _animateToPosition(Offset.zero, 2.0);
    }
  }

  void _animateToPosition(Offset targetOffset, double targetScale) {
    final offsetTween = Tween<Offset>(begin: _panOffset, end: targetOffset);
    final scaleTween = Tween<double>(begin: _scale, end: targetScale);
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animation!.addListener(() {
      setState(() {
        _panOffset = offsetTween.evaluate(_animation!);
        _scale = scaleTween.evaluate(_animation!);
      });
    });
    
    _animationController.forward(from: 0);
  }

  void _startDismiss() {
    _isDismissing = true;
    _dismissAnimation = Tween<Offset>(
      begin: _panOffset,
      end: Offset(0, _panOffset.dy > 0 ? 400 : -400),
    ).animate(CurvedAnimation(
      parent: _dismissController,
      curve: Curves.easeOut,
    ));
    
    _dismissAnimation!.addListener(() {
      setState(() {
        _panOffset = _dismissAnimation!.value;
        _dismissProgress = _dismissController.value;
      });
    });
    
    _dismissController.forward().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = 1.0 - (_dismissProgress * 0.7);
    
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(opacity),
      body: Stack(
        children: [
          // Main image viewer
          GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            onDoubleTap: _onDoubleTap,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(_panOffset.dx, _panOffset.dy)
                  ..scale(_scale),
                child: Center(
                  child: widget.heroTag != null
                      ? Hero(
                          tag: widget.heroTag!,
                          child: _buildImage(),
                        )
                      : _buildImage(),
                ),
              ),
            ),
          ),
          
          // Close button - positioned more accessibly
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: _close,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
            // Dismiss hint - shows initially, then on gesture
          if (_showDismissHint || (_dismissProgress > 0 && !_isDismissing))
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showDismissHint ? 0.8 : _dismissProgress,
                duration: Duration(milliseconds: _showDismissHint ? 0 : 100),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _showDismissHint 
                          ? 'Swipe up or down to dismiss' 
                          : '↑ Release to dismiss ↓',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ),              ),
            ),
          
          // Dismiss progress indicator
          if (_dismissProgress > 0 && !_isDismissing && _isVerticalGesture)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(_dismissProgress * 0.3),
                    ],
                  ),
                ),
              ),
            ),
          
          // Scale indicator
          if (_scale > 1.1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(_scale * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageProvider is CachedNetworkImageProvider) {
      final provider = widget.imageProvider as CachedNetworkImageProvider;
      return CachedNetworkImage(
        imageUrl: provider.url,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        ),
      );
    } else if (widget.imageProvider is FileImage) {
      final provider = widget.imageProvider as FileImage;
      return Image.file(
        provider.file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        ),
      );
    } else {
      return Image(
        image: widget.imageProvider,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        ),
      );
    }
  }
}

/// Helper function to show the custom image viewer
void showCustomImageViewer(
  BuildContext context,
  ImageProvider imageProvider, {
  String? heroTag,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: animation,
        child: CustomImageViewer(
          imageProvider: imageProvider,
          heroTag: heroTag,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    ),
  );
}
