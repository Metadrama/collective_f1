import 'package:flutter/material.dart';

/// A floating tooltip that appears above a widget, similar to a Material tooltip but with more control.
class FloatingTooltip {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    hide();
    final overlay = Overlay.of(context);
    final renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    _currentEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: targetPosition.dx,
          top: targetPosition.dy - 38, // Show above the field
          width: targetSize.width,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_currentEntry!);
    Future.delayed(duration, hide);
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
