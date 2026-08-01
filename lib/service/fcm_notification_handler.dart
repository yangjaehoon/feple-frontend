import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class FcmNotificationHandler {
  static const _channelId = 'feple_high_importance';
  static const _imageDownloadTimeout = Duration(seconds: 5);

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<void> Function(Map<String, dynamic> data) onTap;

  FcmNotificationHandler(this._plugin, {required this.onTap});

  Future<void> initialize() async {
    final channel = AndroidNotificationChannel(
      _channelId,
      'fcm_channel_name'.tr(),
      description: 'fcm_channel_desc'.tr(),
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );
  }

  Future<void> handleForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _plugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'fcm_channel_name'.tr(),
          channelDescription: 'fcm_channel_desc'.tr(),
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          styleInformation: await _buildBigPictureStyle(notification.android?.imageUrl),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // 앱이 포그라운드일 때만 해당 — 백그라운드/종료 상태 알림 이미지는 OS가
  // FCM notification.image 필드로 직접 렌더링(서버 페이로드만 있으면 동작).
  // iOS는 로컬 알림 첨부에 파일 경로가 필요해(byte 배열 불가) 여기선 생략 —
  // 지원하려면 Notification Service Extension이 필요한 별도 네이티브 작업.
  Future<BigPictureStyleInformation?> _buildBigPictureStyle(String? imageUrl) async {
    if (imageUrl == null || !Platform.isAndroid) return null;
    try {
      final response = await http.get(Uri.parse(imageUrl)).timeout(_imageDownloadTimeout);
      if (response.statusCode != 200) return null;
      return BigPictureStyleInformation(ByteArrayAndroidBitmap(response.bodyBytes));
    } catch (e) {
      debugPrint('[FCM] 알림 이미지 다운로드 실패: $e');
      return null;
    }
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      onTap(data);
    } catch (_) {}
  }
}
