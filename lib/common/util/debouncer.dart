import 'dart:async';

import 'package:flutter/foundation.dart';

/// 연속 호출을 [delay] 만큼 뭉쳐 마지막 것만 실행한다.
///
/// 검색어 입력처럼 자주 바뀌는 트리거에 붙여 네트워크/필터 호출을 줄인다.
/// 소유자(State/Notifier)는 dispose 시 [dispose]를 호출해 잔여 타이머를 정리해야 한다.
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  /// 대기 중인 실행이 있는지.
  bool get isPending => _timer?.isActive ?? false;

  /// [action] 실행을 [delay] 뒤로 예약한다. 이전 예약은 취소된다.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 대기 중인 실행을 취소한다. (예: 즉시 제출로 디바운스를 건너뛸 때)
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
