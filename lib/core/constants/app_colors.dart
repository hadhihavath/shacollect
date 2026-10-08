import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF0F766E); // Deep Teal
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF115E59);
  
  static const Color secondary = Color(0xFF0284C7); // Sky Blue
  static const Color secondaryLight = Color(0xFF38BDF8);
  
  static const Color accent = Color(0xFF10B981); // Emerald Green (Success / Recovery)
  
  // Background & Surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Paid / Zero Balance
  static const Color warning = Color(0xFFF59E0B); // Moderate Balance (< 5,000)
  static const Color danger = Color(0xFFEF4444);  // High Overdue (>= 5,000)
  static const Color info = Color(0xFF3B82F6);
  
  // Payment Mode Specific Colors
  static const Color cashColor = Color(0xFF15803D); // Dark Green
  static const Color gpayColor = Color(0xFF1D4ED8); // Google Pay Blue
  static const Color bankColor = Color(0xFF7C3AED); // Company Account Violet
  
  // Text & Neutral
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFCBD5E1);
}
