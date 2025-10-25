import 'package:flutter/material.dart';

class IndeterminateProgressBar extends StatefulWidget {
  final double height;
  final Color color;
  final Duration duration;

  const IndeterminateProgressBar({
    super.key,
    this.height = 1.5,
    required this.color,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<IndeterminateProgressBar> createState() =>
      _IndeterminateProgressBarState();
}

class _IndeterminateProgressBarState extends State<IndeterminateProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true); // Ping-pong animation

    // Animate a value from 0.0 to 1.0
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ), // Smoother curve
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final barWidth =
                constraints.maxWidth * 0.3; // Width of the moving segment
            // Calculate position based on the 0.0-1.0 animation value
            // This makes the bar move from left edge to right edge
            final position =
                _animation.value * (constraints.maxWidth - barWidth);

            return SizedBox(
              width: double.infinity,
              height: widget.height,
              child: Stack(
                children: [
                  Positioned(
                    left: position, // Position is now directly from animation
                    child: Container(
                      width: barWidth,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
