import 'package:flutter/material.dart';

class AppColors {
  // === Kawaii / Pastel Palette (from HTML mockups) ===

  // Primary & Secondary
  static const Color skyBlue = Color(0xFF5CC0EB);
  static const Color skyBlueLight = Color(0xFFA1DDF5);
  static const Color sunnyYellow = Color(0xFFFDE74C);
  static const Color sunnyYellowLight = Color(0xFFFFE68C);

  // Kawaii Accents
  static const Color kawaiiPink = Color(0xFFFFB7D2);
  static const Color kawaiiPurple = Color(0xFFE0C3FC);
  static const Color kawaiiMint = Color(0xFFB5EADD);
  static const Color accentPink = Color(0xFFF9A8D4);
  static const Color accentPurple = Color(0xFFD8B4FE);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color backgroundCreamy = Color(0xFFFFFDFA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textMain = Color(0xFF2D3748);
  static const Color textMuted = Color(0xFF718096);
  static const Color textDark = Color(0xFF0E171B);
  static const Color textBlueMuted = Color(0xFF4F8196);

  // Legacy (kept for backward compat)
  static const Color veryDarkGrey = Color.fromARGB(255, 18, 18, 18);
  static const Color darkGrey = Color.fromARGB(255, 45, 45, 45);
  static const Color grey = Color.fromARGB(255, 139, 139, 139);
  static const Color middleGrey = Color.fromARGB(255, 171, 171, 171);
  static const Color brightGrey = Color.fromARGB(255, 228, 228, 228);
  static const Color blueGreen = Color.fromARGB(255, 0, 185, 206);
  static const Color green = Color.fromARGB(255, 132, 206, 191);
  static const Color darkGreen = Color.fromARGB(255, 101, 160, 149);
  static const Color blue = Color.fromARGB(255, 0, 125, 203);
  static const Color darkBlue = Color.fromARGB(255, 0, 70, 111);
  static const Color mediumBlue = Color.fromARGB(255, 60, 140, 180);
  static const Color darkOrange = Color.fromARGB(255, 222, 112, 48);
  static const Color faleBlue = Color.fromARGB(255, 160, 206, 222);
  static const Color brightBlue = Color.fromARGB(255, 123, 182, 212);
  static const Color salmon = Color(0xffff6666);

  // === Semantic UI Colors ===

  /// Form validation error / destructive action
  static const Color errorRed = Color(0xFFFF4D4F);

  /// Success state (loading button, password validation)
  static const Color successGreen = Color(0xFF00C896);

  /// Pending / warning state (인증 대기 등)
  static const Color statusPending = Color(0xFFFF9800);

  /// Kakao login button background
  static const Color kakaoYellow = Color(0xFFFEE500);

  /// Kakao login button text/icon
  static const Color kakaoText = Color(0xFF3C1E1E);

  /// Offline banner background
  static const Color offlineBannerBg = Color(0xFF2D2D3A);

  // === Booth Type Colors ===
  static const Color boothFood = Color(0xFFFF7043);
  static const Color boothAlcohol = Color(0xFFFFA000);
  static const Color boothEvent = Color(0xFF7B1FA2);
}
