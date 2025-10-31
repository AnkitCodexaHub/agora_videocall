import 'package:flutter/material.dart';

/// Application color constants
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFFE4405F);
  static const Color secondary = Color(0xFF4A90E2);

  // Background Colors
  static const Color background = Color(0xFF111111);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2E2E2E);

  // Status Colors
  static const Color muted = Colors.red;
  static const Color active = Colors.green;
  static const Color cameraActive = Colors.blue;
  static const Color handRaised = Colors.yellow;
  static const Color handRaisedDark = Color(0xFFF9A825);
  static const Color speaking = Colors.blueAccent;

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  // Overlay Colors
  static const Color overlayDark = Colors.black54;
  static final Color overlayLight = Colors.white.withValues(alpha: 0.2);

  // Error Colors
  static const Color error = Colors.red;

  // Avatar Colors
  static const Color avatarHost = Colors.blue;
  static const Color avatarDefault = Colors.grey;
}

