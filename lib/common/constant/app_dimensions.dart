/// 앱 전체에서 공유하는 레이아웃 상수
///
/// 매직넘버 대신 이 상수를 사용하세요.
class AppDimens {
  AppDimens._(); // 인스턴스화 방지

  // ── AppBar ──
  static const double appBarHeight = 50.0;

  // ── Scroll padding (Stack 레이아웃에서 앱바/탭바 가림 방지) ──
  static const double scrollPaddingTop = appBarHeight;
  static const double scrollPaddingBottom = 50.0;
  static const double scrollPaddingBottomLarge = 100.0;
  static const double fabBottomPadding = 80.0;

  // ── Shape (MD3 기준) ──
  // Extra Small(4) · Small(8) · Medium(12) · Large(16) · Extra Large(28)
  static const double shapeInput = 12.0;    // 입력 필드 — Medium
  static const double shapeButton = 16.0;   // 버튼 — Large
  static const double shapeDialog = 28.0;   // 다이얼로그 — Extra Large
  static const double shapeSheet = 28.0;    // 바텀시트 상단 — Extra Large

  // ── Card / Container ──
  static const double cardRadius = 20.0;
  static const double cardRadiusSmall = 16.0;
  static const double cardRadiusTiny = 12.0;
  static const double boardCardHeight = 280.0;
  static const double boardHeaderHeight = 35.0;

  // ── Spacing ──
  static const double paddingHorizontal = 16.0;
  static const double paddingVertical = 8.0;

  // ── Icon ──
  static const double iconSizeSm = 14.0;
  static const double iconSizeMd = 16.0;
  static const double iconSizeLg = 18.0;

  // ── Font ──
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 13.0;
  static const double fontSizeMd = 14.0;
  static const double fontSizeLg = 15.0;
  static const double fontSizeXl = 16.0;
  static const double fontSizeTitle = 20.0;
}
