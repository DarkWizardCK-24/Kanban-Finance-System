import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Green Accent Shades (Primary Palette)
  static const Color greenAccent = Color(0xFF69F0AE);
  static const Color greenAccentLight = Color(0xFFB9F6CA);
  static const Color greenAccentDark = Color(0xFF00C853);
  static const Color greenAccentDeep = Color(0xFF00E676);

  // Secondary Colors
  static const Color primaryCyan = Color(0xFF00ACC1);
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryAmber = Color(0xFFFFA000);
  static const Color primaryYellow = Color(0xFFFDD835);

  // Light Variants
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color lightCyan = Color(0xFFE0F7FA);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color lightAmber = Color(0xFFFFF8E1);
  static const Color lightYellow = Color(0xFFFFFDE7);

  // Accent Colors
  static const Color cyanAccent = Color(0xFF18FFFF);
  static const Color blueAccent = Color(0xFF448AFF);

  // Neutral
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF29B6F6);

  // Kanban Column Colors
  static const Color kanbanPending = Color(0xFFFFF3E0);
  static const Color kanbanProcessing = Color(0xFFE1F5FE);
  static const Color kanbanCompleted = Color(0xFFE8F5E9);
  static const Color kanbanFailed = Color(0xFFFFEBEE);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [greenAccentDark, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient wealthGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF004D40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
