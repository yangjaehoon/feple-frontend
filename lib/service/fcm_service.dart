import 'dart:async';
import 'dart:io';
import 'package:feple/network/dio_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 백그라운드 메시지 핸들러 — 최상위 함수여야 함
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드에서는 시스템이 자동으로 알림 표시
  debugPrint('[FCM] 백그라운드 메시지: ${message.notification?.title}');
}

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _messageSubscription;
  StreamSubscription? _tokenSubscription;

  static const _androidChannel = AndroidNotificationChannel(
    'feple_high_importance',
    'FEPLE 알림',
    description: '팔로우 아티스트 신규 페스티벌 알림',
    importance: Importance.high,
  );

  Future<void> init() async {
    // 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 권한 요청
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] 권한 상태: ${settings.authorizationStatus}');

    // Android 알림 채널 생성
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // local_notifications 초기화
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(initSettings);

    // 중복 등록 방지
    _messageSubscription?.cancel();
    _tokenSubscription?.cancel();

    // 포그라운드 메시지 처리
    _messageSubscription =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 토큰 등록
    await _registerToken();

    // 토큰 갱신 시 재등록
    _tokenSubscription =
        _messaging.onTokenRefresh.listen(_sendTokenToServer);
  }

  Future<void> _registerToken() async {
    try {
      String? token;
      if (Platform.isIOS) {
        // iOS는 APNs 토큰 먼저 요청
        await _messaging.getAPNSToken();
      }
      token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('[FCM] 토큰 등록 실패: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await DioClient.dio.post('/users/device-token', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
      debugPrint('[FCM] 토큰 서버 등록 완료');
    } catch (e) {
      debugPrint('[FCM] 토큰 서버 등록 실패: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
