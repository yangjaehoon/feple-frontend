import 'dart:async';
import 'dart:io';
import 'package:feple/auth/token_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmTokenService {
  final FirebaseMessaging _messaging;

  // APNs/FCM 토큰 조회는 네트워크·플랫폼 상태에 따라 오래 걸릴 수 있어 상한을 둔다
  // (unregister와 동일). 없으면 로그인 직후 토큰 등록이 무기한 매달릴 수 있음.
  static const _tokenTimeout = Duration(seconds: 5);

  FcmTokenService(this._messaging);

  Future<void> register({String language = 'ko'}) async {
    try {
      if (Platform.isIOS) {
        await _messaging.getAPNSToken().timeout(_tokenTimeout);
      }
      final token = await _messaging.getToken().timeout(_tokenTimeout);
      if (token != null) await sendToServer(token, language: language);
    } catch (e, st) {
      _reportFailure('토큰 등록', e, st);
    }
  }

  Future<void> sendToServer(String token, {String language = 'ko'}) async {
    try {
      await DioClient.dio.post('/users/device-token', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'language': language,
      });
      debugPrint('[FCM] 토큰 서버 등록 완료');
    } catch (e, st) {
      _reportFailure('토큰 서버 등록', e, st);
    }
  }

  Future<void> unregister() async {
    try {
      final jwt = await TokenStore.readAccessToken();
      if (jwt == null || jwt.isEmpty) return;
      final token = await _messaging.getToken().timeout(_tokenTimeout);
      if (token == null) return;
      await DioClient.dio.delete('/users/device-token', data: {'token': token});
      debugPrint('[FCM] 토큰 서버 삭제 완료');
    } catch (e, st) {
      _reportFailure('토큰 서버 삭제', e, st);
    }
  }

  void _reportFailure(String action, Object e, StackTrace st) {
    debugPrint('[FCM] $action 실패: $e');
    unawaited(FirebaseCrashlytics.instance.recordError(e, st, fatal: false, reason: 'FCM $action failed'));
  }
}
