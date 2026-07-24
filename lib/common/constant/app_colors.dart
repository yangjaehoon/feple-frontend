import 'package:flutter/material.dart';

class AppColors {
  // === Kawaii / Pastel Palette (from HTML mockups) ===

  // Primary & Secondary
  static const Color skyBlue = Color(0xFF5CC0EB);
  static const Color skyBlueLight = Color(0xFFA1DDF5);
  static const Color sunnyYellow = Color(0xFFFDE74C);

  // Kawaii Accents
  static const Color kawaiiPink = Color(0xFFFFB7D2);
  static const Color kawaiiPurple = Color(0xFFE0C3FC);
  static const Color kawaiiMint = Color(0xFFB5EADD);
  static const Color accentPink = Color(0xFFF9A8D4);
  static const Color accentPurple = Color(0xFFD8B4FE);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textMain = Color(0xFF2D3748);
  static const Color textMuted = Color(0xFF718096);

  // === Semantic UI Colors ===

  /// Form validation error / destructive action
  static const Color errorRed = Color(0xFFFF4D4F);

  /// Success state (loading button, password validation)
  static const Color successGreen = Color(0xFF4CAF50);

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

  // === Badge Colors (user role / certification) ===
  static const Color badgeAdmin = Color(0xFF673AB7);      // deepPurple
  static const Color badgeArtist = Color(0xFF2196F3);     // blue
  static const Color badgeCertified = Color(0xFF009688);  // teal

  // === Notification Colors ===
  static const Color notificationReminder = Color(0xFFFF7043); // festival reminder
  static const Color infoBlue = Color(0xFF4A90E2);             // info snackbar

  // === Age Restriction Colors ===
  static const Color ageRatingBlue = Color(0xFF5CC0EB);       // ALL_AGES
  static const Color ageRatingLightGreen = Color(0xFF81C784); // AGE_8
  static const Color ageRatingGreen = Color(0xFF4CAF50);      // AGE_12
  static const Color ageRatingOrange = statusPending;         // AGE_15
  static const Color ageRatingRed = Color(0xFFF44336);        // AGE_19

  // === Weather Colors (강수 확률 단계) ===
  static const Color rainProbHigh   = Color(0xFF1565C0); // 70% 이상
  static const Color rainProbMedium = Color(0xFF42A5F5); // 40–69%
  static const Color rainProbLow    = Color(0xFF90CAF9); // 40% 미만

  // === UI Misc ===
  static const Color hotPink    = Color(0xFFFF6B8A); // 사진 뷰어 좋아요 하트
  static const Color markerGray = Color(0xFF555555); // 지도 마커 폴백
  static const Color onboardingPink = Color(0xFFFFE4EF); // 온보딩 카드 핑크
  static const Color onboardingMint = Color(0xFFD4F5EC); // 온보딩 카드 민트

  // === Skeleton Loading ===
  static const Color skeletonBaseDark       = Color(0xFF2C2C2C);
  static const Color skeletonHighlightDark  = Color(0xFF3E3E3E);
  static const Color skeletonBaseLight      = Color(0xFFE0E0E0);
  static const Color skeletonHighlightLight = Color(0xFFF0F0F0);

}
