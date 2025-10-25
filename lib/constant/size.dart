import 'package:flutter/material.dart';

/// Comprehensive sizing constants for the entire app.
///
/// Usage:
/// 1. Import this file: `import 'package:collective/constant/size.dart';`
/// 2. Use constants directly: `padding: SizeConstants.paddingMedium`
/// 3. For EdgeInsets, use predefined constants: `padding: SizeConstants.paddingAllLarge`
///
/// Guidelines:
/// - Prefer using these constants over hardcoded values
/// - For new values, add them here first before using
/// - Keep related constants grouped together
/// - Follow the naming pattern: `categorySize` (e.g. textSmall, iconLarge)
///
/// Categories:
/// - Spacing (padding, margin)
/// - Text sizes
/// - Icon sizes
/// - Border radius
/// - Animation durations
/// - Other dimensions
class SizeConstants {
  // Spacing
  static const double paddingSmall = 4.0;
  static const double paddingMedium = 8.0;
  static const double paddingLarge = 12.0;
  static const double paddingXLarge = 16.0;
  static const double paddingXXLarge = 24.0;

  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(
    horizontal: paddingSmall,
  );
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(
    horizontal: paddingMedium,
  );
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(
    horizontal: paddingLarge,
  );
  static const EdgeInsets paddingHorizontalXLarge = EdgeInsets.symmetric(
    horizontal: paddingXLarge,
  );
  static const EdgeInsets paddingHorizontalXXLarge = EdgeInsets.symmetric(
    horizontal: paddingXXLarge,
  );

  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(
    vertical: paddingSmall,
  );
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(
    vertical: paddingMedium,
  );
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(
    vertical: paddingLarge,
  );
  static const EdgeInsets paddingVerticalXLarge = EdgeInsets.symmetric(
    vertical: paddingXLarge,
  );
  static const EdgeInsets paddingVerticalXXLarge = EdgeInsets.symmetric(
    vertical: paddingXXLarge,
  );

  static const EdgeInsets paddingAllSmall = EdgeInsets.all(paddingSmall);
  static const EdgeInsets paddingAllMedium = EdgeInsets.all(paddingMedium);
  static const EdgeInsets paddingAllLarge = EdgeInsets.all(paddingLarge);
  static const EdgeInsets paddingAllXLarge = EdgeInsets.all(paddingXLarge);
  static const EdgeInsets paddingAllXXLarge = EdgeInsets.all(paddingXXLarge);

  static const EdgeInsets paddingInput = EdgeInsets.fromLTRB(5, 0, 5, 2);
  static const EdgeInsets paddingToolbar = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 12,
  );

  // Text sizes
  static const double textXXSmall = 11.0;
  static const double textXSmall = 13.0;
  static const double textSmall = 14.0;
  static const double textMedium = 15.0;
  static const double textLarge = 18.0;
  static const double textXLarge = 22.0;
  static const double textXXLarge = 48.0;

  // Icon sizes
  static const double iconXSmall = 15.0;
  static const double iconSmall = 18.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;

  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 10.0;
  static const double borderRadiusXLarge = 12.0;

  // Animation durations
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);

  // Other dimensions
  static const double emojiBarHeight = 33.0;
  static const double dividerHeight = 1.0;
  static const double sectionSpacingSmall = 10.0;
  static const double sectionSpacingMedium = 12.0;
  static const double sectionSpacingLarge = 16.0;
}
