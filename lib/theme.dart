import 'package:flutter/material.dart';
import 'package:collective/constant/size.dart';

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  fontFamily: 'IBM Plex Sans',
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  ),
  textTheme: TextTheme(
    // Removed const
    displayLarge: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: SizeConstants.textXXLarge,
      letterSpacing: -1,
      color: Colors.black,
    ),
    titleMedium: TextStyle(
      fontFamily: 'IBM Plex Sans',
      fontSize:
          SizeConstants.textXLarge + 2, // Increased size for differentiation
      fontWeight: FontWeight.w600, // Added weight
      height: 1.55,
      color: Colors.black,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'IBM Plex Sans',
      fontSize: SizeConstants.textXLarge,
      height: 1.55,
      color: Colors.black,
    ),
    bodySmall: TextStyle(
      // Added bodySmall
      fontFamily: 'IBM Plex Sans',
      fontSize: SizeConstants.textSmall, // Using textSmall (14.0)
      color: Colors.black.withOpacity(
        0.55,
      ), // Reduced contrast for secondary text
    ),
  ),
  iconTheme: IconThemeData(
    // Added iconTheme
    color: Colors.black.withOpacity(
      0.5,
    ), // Reduced opacity for less apparent unselected icons
    size: SizeConstants.iconMedium,
  ),
  highlightColor: Colors.deepPurple.withOpacity(0.15),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SizeConstants.borderRadiusSmall),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SizeConstants.borderRadiusSmall),
      borderSide: const BorderSide(width: 1.5),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConstants.borderRadiusLarge),
      ),
      padding: SizeConstants.paddingButton,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.deepPurple,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  fontFamily: 'IBM Plex Sans',
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  ),
  textTheme: TextTheme(
    // Removed const
    displayLarge: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: SizeConstants.textXXLarge,
      letterSpacing: -1,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontFamily: 'IBM Plex Sans',
      fontSize:
          SizeConstants.textXLarge + 2, // Increased size for differentiation
      fontWeight: FontWeight.w600, // Added weight
      height: 1.55,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'IBM Plex Sans',
      fontSize: SizeConstants.textXLarge,
      height: 1.55,
      color: Colors.white,
    ),
    bodySmall: TextStyle(
      // Added bodySmall
      fontFamily: 'IBM Plex Sans',
      fontSize: SizeConstants.textSmall, // Using textSmall (14.0)
      color: Colors.white.withOpacity(
        0.6,
      ), // Reduced contrast for secondary text
    ),
  ),
  iconTheme: IconThemeData(
    // Added iconTheme
    color: Colors.white.withOpacity(
      0.5,
    ), // Reduced opacity for less apparent unselected icons
    size: SizeConstants.iconMedium,
  ),
  highlightColor: Colors.deepPurpleAccent.withOpacity(0.2),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SizeConstants.borderRadiusSmall),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SizeConstants.borderRadiusSmall),
      borderSide: const BorderSide(width: 1.5),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConstants.borderRadiusLarge),
      ),
      padding: SizeConstants.paddingButton,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.purpleAccent[100],
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
);
