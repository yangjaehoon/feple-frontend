import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:feple/app.dart';
import 'package:feple/auth/token_store.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/permission_rationale.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/notification_type.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/notification/s_notification.dart';
import 'package:feple/service/festival_service.dart';
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
  StreamSubscription? _openedAppSubscription;

  static const _androidChannel = AndroidNotificationChannel(
    'feple_high_importance',
    'FEPLE 알림',
    description: '팔로우 아티스트 신규 페스티벌 알림',
    importance: Importance.high,
  );

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] 권한 상태: ${settings.authorizationStatus}');
    await _setupChannelsAndListeners();
  }

  /// 알림 권한을 처음 요청하는 경우 사전 설명 바텀시트를 먼저 표시.
  /// 이미 권한이 결정된 경우(허용/거부)에는 바텀시트 없이 바로 진행.
  Future<void> initWithRationale() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final current = await _messaging.getNotificationSettings();
    final needsRationale =
        current.authorizationStatus == AuthorizationStatus.notDetermined;

    bool requestPermission = true;
    if (needsRationale) {
      final ctx = App.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        requestPermission = await PermissionRationale.showNotification(ctx);
      }
    }

    if (requestPermission) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] 권한 상태: ${settings.authorizationStatus}');
    }

    await _setupChannelsAndListeners();
  }

  Future<void> _setupChannelsAndListeners() async {
    // Android 알림 채널 생성
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // local_notifications 초기화 — 포그라운드 알림 탭 핸들러 등록
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onForegroundNotificationTap,
    );

    // 중복 등록 방지
    _messageSubscription?.cancel();
    _tokenSubscription?.cancel();
    _openedAppSubscription?.cancel();

    // 포그라운드 메시지 수신 → 로컬 알림으로 표시
    _messageSubscription =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드 상태에서 알림 탭 → 앱 포그라운드 전환 시 내비게이션
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (msg) => _navigateFromData(Map<String, dynamic>.from(msg.data)),
    );

    // 앱 종료 상태에서 알림 탭으로 콜드 스타트된 경우 내비게이션
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _navigateFromData(Map<String, dynamic>.from(initialMessage.data));
    }

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

  // 로그아웃 시 호출 — 서버에서 토큰 삭제 후 구독 해제
  // JWT가 아직 유효한 시점에 호출해야 함 (TokenStore.clear() 전)
  Future<void> stop() async {
    await _unregisterFromServer();
    await _messageSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _messageSubscription = null;
    _tokenSubscription = null;
    _openedAppSubscription = null;
  }

  Future<void> _unregisterFromServer() async {
    try {
      // JWT가 없으면(세션 만료 후 logout 재진입 시) 서버 호출 생략
      final jwt = await TokenStore.readAccessToken();
      if (jwt == null || jwt.isEmpty) return;
      // getToken()은 네트워크/APNs 상태에 따라 무기한 대기할 수 있으므로 타임아웃 필수
      final token = await _messaging.getToken()
          .timeout(const Duration(seconds: 5));
      if (token == null) return;
      await DioClient.dio.delete('/users/device-token', data: {'token': token});
      debugPrint('[FCM] 토큰 서버 삭제 완료');
    } catch (e) {
      debugPrint('[FCM] 토큰 서버 삭제 실패: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // data를 payload로 저장해두어 탭 시 내비게이션에 사용
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
      payload: jsonEncode(message.data),
    );
  }

  void _onForegroundNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (_) {}
  }

  Future<void> _navigateFromData(Map<String, dynamic> data) async {
    final nav = App.navigatorKey.currentState;
    if (nav == null) return;

    final type = NotificationType.fromValue(data['type'] as String?);
    final festivalIdStr = data['festivalId'] as String?;
    final festivalId = (festivalIdStr?.isNotEmpty == true)
        ? int.tryParse(festivalIdStr!)
        : null;

    if (festivalId != null && _isFestivalLinked(type)) {
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

  /// 페스티벌 ID로 직접 이동하는 알림 타입
  bool _isFestivalLinked(NotificationType? type) {
    return type == NotificationType.newFestival ||
        type == NotificationType.festivalReminder ||
        type == NotificationType.certApproved ||
        type == NotificationType.certRejected;
  }
}
