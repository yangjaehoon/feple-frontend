import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 앱 아이콘 배지 카운트.
///
/// iOS는 네이티브 API(`UIApplication.applicationIconBadgeNumber`)로 정확한
/// 숫자를 표시할 수 있어 지원한다(알림 배지 권한은 `FcmService`가 이미 요청).
/// Android는 표준 OS API가 없고 런처마다 제각각인 비공식 브로드캐스트에
/// 의존해야 해서 구현하지 않는다 — 대신 시스템 알림함에 안 읽은 알림이 남아
/// 있으면 대부분의 런처가 자동으로 점(dot)을 띄워준다.
class AppBadge {
  AppBadge._();

  static const _channel = MethodChannel('com.dobino.feple/badge');

  static Future<void> setCount(int count) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('setBadgeCount', {'count': count});
    } catch (e) {
      debugPrint('[AppBadge] 배지 설정 실패: $e');
    }
  }
}
