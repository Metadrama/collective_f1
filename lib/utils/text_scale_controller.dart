import 'package:flutter/foundation.dart';

/// Singleton controller for global text scaling.
class TextScaleController {
  static final TextScaleController instance = TextScaleController._internal();
  final ValueNotifier<double> scale = ValueNotifier<double>(1.0);

  TextScaleController._internal();

  void setScale(double newScale) {
    scale.value = newScale.clamp(0.7, 2.5);
  }
}
