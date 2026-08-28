import 'dart:async';

import 'package:feple/app.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/model/notification_type.dart';
import 'package:feple/screen/notification/notification_destination.dart';
import 'package:feple/screen/notification/s_notification.dart';
import 'package:flutter/widgets.dart';

class FcmNavigationHandler {
  Future<void> navigate(Map<String, dynamic> data) async {
    final nav = App.navigatorKey.currentState;
    if (nav == null) return;

    final type = NotificationType.fromValue(data['type'] as String?);
    // 백엔드가 linkId 키에 타입에 따라 festivalId 뿐 아니라 postId/artistId도
    // 함께 실어 보냄 (FcmPushService.buildMulticastMessage) — 범용 참조 ID로 취급.
    // festivalId는 linkId 도입 전 구버전 클라이언트와의 호환을 위한 폴백.
    final linkIdStr = (data['linkId'] as String?) ?? (data['festivalId'] as String?);
    final linkId = (linkIdStr?.isNotEmpty == true) ? int.tryParse(linkIdStr!) : null;

    try {
      final screen = await resolveNotificationDestination(type, linkId);
      if (screen != null) {
        unawaited(nav.push(SlideRoute(builder: (_) => screen)));
        return;
      }
    } catch (e) {
      debugPrint('[FCM Nav] 알림 이동 실패: $e');
    }
    unawaited(nav.push(SlideRoute(builder: (_) => const NotificationScreen())));
  }
}
