import 'dart:async';
import 'dart:io';
import 'package:feple/auth/token_store.dart';
import 'package:feple/network/dio_client.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmTokenService {
  final FirebaseMessaging _messaging;

  FcmTokenService(this._messaging);

  Future<void> register({String language = 'ko'}) async {
    try {
      if (Platform.isIOS) {
        await _messaging.getAPNSToken();
      }
      final token = await _messaging.getToken();
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
      final token = await _messaging.getToken().timeout(const Duration(seconds: 5));
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
