import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmNotificationHandler {
  static const _channelId = 'feple_high_importance';

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

    // ic_notification: 흰색 모노크롬 PNG — Android Studio Image Asset으로 생성 후 drawable/ 에 추가 필요
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );
  }

  void handleForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _plugin.show(
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
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
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
