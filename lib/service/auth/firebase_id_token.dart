import 'package:firebase_auth/firebase_auth.dart';

import '../../common/exception/auth_exchange_exception.dart';

/// Firebase [User]에서 ID 토큰 문자열을 꺼낸다.
/// user가 없거나 토큰이 null/빈 문자열이면 [AuthExchangeException]으로 통일한다 —
/// `credential.user!` / `idToken!` 강제 언랩이 raw null-check 예외를 UI로
/// 흘려보내던 것을 방지.
Future<String> requireFirebaseIdToken(
  User? user, {
  bool forceRefresh = false,
}) async {
  if (user == null) {
    throw AuthExchangeException('firebase credential has no user');
  }
  final token = await user.getIdToken(forceRefresh);
  if (token == null || token.isEmpty) {
    throw AuthExchangeException('firebase id token is null');
  }
  return token;
}
