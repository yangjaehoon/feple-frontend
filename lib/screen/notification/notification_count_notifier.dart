import 'dart:async';

import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/common/util/app_badge.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:flutter/foundation.dart';

/// 앱바 알림 배지 전용 카운터.
///
/// 다른 화면별 Notifier와 달리 Provider가 아니라 GetIt 싱글톤으로 등록된다
/// (`injection.dart`) — [FepleAppBar]가 여러 탭 화면에서 각각 새로 생성되는
/// 위젯이라, 상위 트리에 Provider를 하나 심어두지 않는 한 화면마다 별도의
/// count 상태를 갖게 되어 배지가 안 맞을 수 있기 때문. 싱글톤으로 두면 어느
/// 탭의 앱바든 항상 같은 인스턴스를 구독해 배지가 일관되게 유지된다.
/// `load()`는 자동 갱신되지 않고 [FepleAppBar]가 `initState`/알림 화면 복귀
/// 시점에 명시적으로 호출한다 — 읽음 처리 흐름을 새로 추가할 때 호출을
/// 빠뜨리지 않도록 주의할 것.
class NotificationCountNotifier extends SafeChangeNotifier {
  final _service = sl<NotificationCountable>();

  int _count = 0;
  int get count => _count;

  // clear()가 진행 중인 load()보다 먼저 끝나면(예: 조회 중 로그아웃) load()가
  // 뒤늦게 돌아와 이전 계정의 카운트로 배지를 덮어쓸 수 있다 — 세대 번호로
  // 그 사이 clear()/load()가 다시 호출됐는지 판별해 낡은 결과를 버린다.
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    try {
      final count = await _service.getUnreadCount();
      if (generation != _generation) return;
      _count = count;
      safeNotify();
      unawaited(AppBadge.setCount(_count));
    } catch (e) {
      debugPrint('[NotificationCount] 로드 실패: $e');
    }
  }

  void clear() {
    _generation++;
    _count = 0;
    safeNotify();
    unawaited(AppBadge.setCount(0));
  }
}
