import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SlidableOpenTrigger extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onStartFullyOpen;
  final Future<void> Function()? onEndFullyOpen;
  final double triggerFraction;

  const SlidableOpenTrigger({
    super.key,
    required this.child,
    this.onStartFullyOpen,
    this.onEndFullyOpen,
    this.triggerFraction = 0.95,
  });

  @override
  State<SlidableOpenTrigger> createState() => _SlidableOpenTriggerState();
}

class _SlidableOpenTriggerState extends State<SlidableOpenTrigger> {
  SlidableController? _controller;
  bool _triggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachController();
  }

  @override
  void didUpdateWidget(covariant SlidableOpenTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-attach if subtree changed
    _attachController();
  }

  void _attachController() {
    final ctrl = Slidable.of(context);
    if (_controller == ctrl) return;
    _detachController();
    _controller = ctrl;
    if (_controller != null) {
      _controller!.endGesture.addListener(_onEndGestureChanged);
      _controller!.animation.addListener(_onAnimationChanged);
      _controller!.actionPaneType.addListener(_onPaneTypeChanged);
    }
  }

  void _detachController() {
    if (_controller != null) {
      _controller!.endGesture.removeListener(_onEndGestureChanged);
      _controller!.animation.removeListener(_onAnimationChanged);
      _controller!.actionPaneType.removeListener(_onPaneTypeChanged);
      _controller = null;
    }
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }

  void _resetIfClosed() {
    if (_controller == null) return;
    if (_controller!.animation.value <= 0.01) {
      _triggered = false;
    }
  }

  void _onAnimationChanged() {
    _resetIfClosed();
  }

  void _onPaneTypeChanged() {
    // When switching panes, allow triggering again in new direction
    _triggered = false;
  }

  Future<void> _onEndGestureChanged() async {
    if (_controller == null || _triggered) return;

    final pane = _controller!.actionPaneType.value;
    final anim = _controller!.animation.value;

    if (pane == ActionPaneType.start) {
      final threshold = _controller!.startActionPaneExtentRatio * widget.triggerFraction;
      if (anim >= threshold) {
        _triggered = true;
        // Close after triggering to respect UX of reversing direction to close
        try {
          if (widget.onStartFullyOpen != null) {
            await widget.onStartFullyOpen!.call();
          }
        } finally {
          // Close pane after handling
          await _controller!.close();
        }
      }
    } else if (pane == ActionPaneType.end) {
      final threshold = _controller!.endActionPaneExtentRatio * widget.triggerFraction;
      if (anim >= threshold) {
        _triggered = true;
        try {
          if (widget.onEndFullyOpen != null) {
            await widget.onEndFullyOpen!.call();
          }
        } finally {
          await _controller!.close();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Just pass through the child; this widget only listens to Slidable state.
    return widget.child;
  }
}

