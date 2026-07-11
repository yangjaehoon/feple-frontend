import 'dart:async';
import 'package:feple/app.dart';
import 'package:feple/common/language/language.dart';
import 'package:feple/common/util/permission_rationale.dart';
import 'package:feple/service/fcm_navigation_handler.dart';
import 'package:feple/service/fcm_notification_handler.dart';
import 'package:feple/service/fcm_token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] 백그라운드 메시지 수신');
}

class FcmService {
  // 협력 객체(navHandler/tokenService/notifHandler)를 생성자 주입 가능하게 해서
  // 테스트에서 페이크로 교체할 수 있게 함 — 인자 없이 부르면 기존과 동일하게
  // 기본 구현으로 조립됨 (FcmService.instance는 이 기본 경로를 사용)
  factory FcmService({
    FirebaseMessaging? messaging,
    FcmNavigationHandler? navHandler,
    FcmTokenService? tokenService,
    FcmNotificationHandler? notifHandler,
  }) {
    final resolvedMessaging = messaging ?? FirebaseMessaging.instance;
    final resolvedNavHandler = navHandler ?? FcmNavigationHandler();
    return FcmService._(
      messaging: resolvedMessaging,
      navHandler: resolvedNavHandler,
      tokenService: tokenService ?? FcmTokenService(resolvedMessaging),
      notifHandler: notifHandler ??
          FcmNotificationHandler(
            FlutterLocalNotificationsPlugin(),
            onTap: resolvedNavHandler.navigate,
          ),
    );
  }

  FcmService._({
    required FirebaseMessaging messaging,
    required FcmNavigationHandler navHandler,
    required FcmTokenService tokenService,
    required FcmNotificationHandler notifHandler,
  })  : _messaging = messaging,
        _navHandler = navHandler,
        _tokenService = tokenService,
        _notifHandler = notifHandler;

  static final instance = FcmService();

  final FirebaseMessaging _messaging;
  final FcmNavigationHandler _navHandler;
  final FcmNotificationHandler _notifHandler;
  final FcmTokenService _tokenService;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _tokenSubscription;
  StreamSubscription? _openedAppSubscription;

  /// 알림 권한을 처음 요청하는 경우 사전 설명 바텀시트를 먼저 표시.
  /// 이미 권한이 결정된 경우(허용/거부)에는 바텀시트 없이 바로 진행.
  Future<void> initWithRationale() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final current = await _messaging.getNotificationSettings();
    final needsRationale = current.authorizationStatus == AuthorizationStatus.notDetermined;

    bool requestPermission = true;
    if (needsRationale) {
      final ctx = App.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        requestPermission = await PermissionRationale.showNotification(ctx);
      }
    }

    if (requestPermission) {
      final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
      debugPrint('[FCM] 권한 상태: ${settings.authorizationStatus}');
    }

    await _setup();
  }

  String _currentLanguage() => currentLanguage.locale.languageCode;

  // 로그아웃 시 호출 — 서버에서 토큰 삭제 후 구독 해제
  // JWT가 아직 유효한 시점에 호출해야 함 (TokenStore.clear() 전)
  Future<void> stop() async {
    await _tokenService.unregister();
    await _messageSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _messageSubscription = null;
    _tokenSubscription = null;
    _openedAppSubscription = null;
  }

  Future<void> _setup() async {
    await _notifHandler.initialize();

    _messageSubscription?.cancel();
    _tokenSubscription?.cancel();
    _openedAppSubscription?.cancel();

    _messageSubscription = FirebaseMessaging.onMessage.listen(_notifHandler.handleForeground);

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (msg) => _navHandler.navigate(Map<String, dynamic>.from(msg.data)),
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _navHandler.navigate(Map<String, dynamic>.from(initialMessage.data));
    }

    await _tokenService.register(language: _currentLanguage());
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      _tokenService.sendToServer(token, language: _currentLanguage());
    });
  }
}
