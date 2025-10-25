import 'package:flutter/material.dart';

class AnimationUtils {
  static AnimationController createDefaultController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 400),
    );
  }

  static AnimationController createSnapBackController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
  }

  static AnimationController createPulseController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.95,
      upperBound: 1.05,
    );
  }
}
