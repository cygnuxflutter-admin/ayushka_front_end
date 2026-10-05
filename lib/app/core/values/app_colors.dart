import 'package:flutter/material.dart';

/// Centralized color palette derived directly from the official Ayushka Logo.
/// Primary brand color is #384C28 (Deep Earthy Branch Olive).
abstract class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF384C28); // Primary Brand Color (#384C28)
  static const Color primaryLight = Color(0xFF7E9D64); // Fresh Light Leaf Sage
  static const Color primaryDark = Color(0xFF384C28); // Deep Earthy Branch Olive
  static const Color accent = Color(0xFFE98324); // Ayushka Golden Sun / Center Figure Orange
  static const Color secondary = Color(0xFF6B8B50); // Secondary Olive Sage

  // Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF9FAF7); // Soft Natural Off-White
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8DC);
  static const Color dividerLight = Color(0xFFEDF2E8);

  // Backgrounds & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF141F14); // Deep Earthy Night Green
  static const Color surfaceDark = Color(0xFF1D2B1D);
  static const Color cardDark = Color(0xFF1D2B1D);
  static const Color borderDark = Color(0xFF2E422E);
  static const Color dividerDark = Color(0xFF2E422E);

  // Text Colors (Light Mode)
  static const Color textPrimaryLight = Color(0xFF223318); // Deep Organic Forest Text
  static const Color textSecondaryLight = Color(0xFF5A6F50);
  static const Color textMutedLight = Color(0xFF8B9E83);

  // Text Colors (Dark Mode)
  static const Color textPrimaryDark = Color(0xFFF2F7EF);
  static const Color textSecondaryDark = Color(0xFFA5B89F);
  static const Color textMutedDark = Color(0xFF758770);

  // Status & Feedback Colors
  static const Color success = Color(0xFF5A7542);
  static const Color successBg = Color(0xFFF1F5EE);
  static const Color warning = Color(0xFFE98324);
  static const Color warningBg = Color(0xFFFDF3E9);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorBg = Color(0xFFFDE8E8);
  static const Color info = Color(0xFF386641);
  static const Color infoBg = Color(0xFFEEF5EE);

  // Web Sidebar & Shell
  static const Color sidebarBg = Color(0xFF2E3E21); // Deep Organic Olive
  static const Color sidebarItemHover = Color(0xFF435832);
  static const Color sidebarItemActive = Color(0xFF5A7542);
  static const Color sidebarText = Color(0xFFD4E2CA);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
}
