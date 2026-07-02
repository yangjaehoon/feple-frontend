import 'package:feple/app.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/notification_type.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/notification/s_notification.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/foundation.dart';

class FcmNavigationHandler {
  Future<void> navigate(Map<String, dynamic> data) async {
    final nav = App.navigatorKey.currentState;
    if (nav == null) return;

    final type = NotificationType.fromValue(data['type'] as String?);
    final festivalIdStr = data['festivalId'] as String?;
    final festivalId = (festivalIdStr?.isNotEmpty == true)
        ? int.tryParse(festivalIdStr!)
        : null;

    if (festivalId != null && (type?.hasFestivalNavigation ?? false)) {
      try {
        final festival = await sl<FestivalService>().fetchById(festivalId);
        nav.push(SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)));
        return;
      } catch (e) {
        debugPrint('[FCM Nav] 페스티벌 이동 실패: $e');
      }
    }
    nav.push(SlideRoute(builder: (_) => const NotificationScreen()));
  }
}
