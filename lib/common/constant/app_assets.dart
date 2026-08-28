/// 앱 번들 에셋 경로 상수.
class AppAssets {
  AppAssets._();

  /// 프로필 사진을 올리지 않은 사용자의 기본 아바타.
  static const String defaultAvatar = 'assets/image/feple_logo.png';
}

/// 프로필 이미지 URL이 사용자가 직접 올린 사진인지(= 기본 아바타가 아닌지) 판정.
///
/// 서버가 기본 아바타에 대해 URL에 'feple_logo'를 넣어 내려주는 것에 의존하는
/// 취약한 방식이다 — 근본적으로는 서버가 null 또는 `hasCustomAvatar`를 줘야 한다.
/// 그때까지 이 판정 로직을 한 곳에만 둔다.
bool isCustomAvatarUrl(String? url) =>
    url != null && url.isNotEmpty && !url.contains('feple_logo');
