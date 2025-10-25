import 'package:flutter/material.dart';

class EdgeFade extends StatelessWidget {
  final bool top;
  final Color background;

  const EdgeFade({super.key, required this.top, required this.background});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: 12,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [background, background.withAlpha(0)],
            ),
          ),
        ),
      ),
    );
  }
}
