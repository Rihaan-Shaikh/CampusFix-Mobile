import 'package:flutter/material.dart';

/// Centralized color palette for CampusFix Mobile.
///
/// Designed with accessible contrast and cohesive semantic tokens
/// strictly aligned with the CampusFix web application design system.
abstract final class AppColors {
  // Brand Core
  static const Color brandAmber = Color(
    0xFFF59E0B,
  ); // Amber 500 (Primary Brand Accent)
  static const Color brandAmberHover = Color(0xFFD97706); // Amber 600
  static const Color deepNavy = Color(0xFF0E1728); // Deep Campus Navy
  static const Color navyBorder = Color(0xFF243145); // Subtle Navy Ring/Border

  // Material Theme mappings
  static const Color primary = Color(0xFF0E1728); // Deep Campus Navy
  static const Color primaryLight = Color(0xFF2563EB); // Royal Indigo Accent
  static const Color primaryContainer = Color(0xFFEFF6FF);
  static const Color primaryContainerDark = Color(0xFF1E293B);

  static const Color secondary = Color(0xFF475569); // Slate Gray
  static const Color accent = Color(0xFF0D9488); // Teal
  static const Color accentLight = Color(0xFF14B8A6);

  // Semantic Status Colors
  static const Color statusOpen = Color(0xFFD97706); // Amber
  static const Color statusOpenBg = Color(0xFFFEF3C7);
  static const Color statusInProgress = Color(0xFF2563EB); // Blue
  static const Color statusInProgressBg = Color(0xFFEFF6FF);
  static const Color statusResolved = Color(0xFF10B981); // Emerald
  static const Color statusResolvedBg = Color(0xFFDCFCE7);
  static const Color statusCritical = Color(0xFFDC2626); // Crimson
  static const Color statusCriticalBg = Color(0xFFFEE2E2);
  static const Color statusClosed = Color(0xFF64748B); // Slate
  static const Color statusClosedBg = Color(0xFFF1F5F9);

  // Status Dark Backgrounds
  static const Color statusOpenBgDark = Color(0xFF381B03);
  static const Color statusInProgressBgDark = Color(0xFF13234A);
  static const Color statusResolvedBgDark = Color(0xFF062B18);
  static const Color statusCriticalBgDark = Color(0xFF3B0D0D);
  static const Color statusClosedBgDark = Color(0xFF192233);

  // Light Surfaces & Neutrals
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Dark Surfaces & Neutrals
  static const Color darkBackground = Color(0xFF080C14);
  static const Color darkSurface = Color(0xFF0E1726);
  static const Color darkCard = Color(0xFF0E1726);
  static const Color darkBorder = Color(0xFF243145);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF64748B);
}
