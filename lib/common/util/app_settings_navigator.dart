import 'dart:io';
import 'package:feple/service/fcm_notification_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// OS 설정 화면으로 이동시키는 헬퍼.
/// 가능한 경우 목표 항목까지 정확히 짚어줘서, 사용자가 설정 안에서 직접
/// 항목을 찾아 들어가야 하는 부담을 줄인다.
class AppSettingsNavigator {
  AppSettingsNavigator._();

  static const _channel = MethodChannel('com.dobino.feple/settings');

  /// 알림 설정 화면으로 이동.
  /// Android는 앱이 쓰는 알림 채널(`FcmNotificationHandler.channelId`) 화면까지
  /// 바로 이동시킨다(Android 8+ 공식 지원 인텐트). iOS는 채널 개념이 없어
  /// 앱 설정 화면까지만 이동 가능하다(OS 자체 제약).
  static Future<void> openNotificationSettings() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openNotificationChannelSettings', {
          'channelId': FcmNotificationHandler.channelId,
        });
        return;
      } catch (e) {
        debugPrint('[AppSettingsNavigator] 채널 설정 이동 실패: $e');
      }
    }
    await Geolocator.openAppSettings();
  }

  /// 위치 권한 설정 화면으로 이동.
  /// 런타임 권한 개별 항목을 짚어주는 공식 API가 없어 앱 상세 설정까지만
  /// 이동한다(모든 런타임 권한에 공통되는 OS 제약).
  static Future<void> openLocationSettings() => Geolocator.openAppSettings();
}
