import 'package:share_plus/share_plus.dart';

/// OS 공유 시트 호출을 감싼 얇은 인터페이스 — 테스트에서 fake로 교체 가능하도록.
abstract interface class Sharer {
  Future<void> share(ShareParams params);
}

class SystemSharer implements Sharer {
  const SystemSharer();

  @override
  Future<void> share(ShareParams params) => SharePlus.instance.share(params);
}
