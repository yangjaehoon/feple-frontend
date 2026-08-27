import 'dart:async';

import 'package:dio/dio.dart';

/// [body] 실행 중 발생하는 모든 HTTP 요청(GET/POST/…)에 [token]을 자동으로
/// 연결한다. 화면이 dispose되면서 `token.cancel()`을 호출하면 아직 끝나지 않은
/// 요청이 중단되어, dispose된 State/Notifier에 콜백이 도달하는 것을 막는다.
///
/// [withForcedRefresh]와 같은 Zone 전파 방식이라 서비스/모델 계층에
/// `cancelToken` 파라미터를 추가할 필요가 없다.
const _cancelTokenZoneKey = #fepleAmbientCancelToken;

Future<T> withCancelScope<T>(CancelToken token, Future<T> Function() body) =>
    runZoned(body, zoneValues: {_cancelTokenZoneKey: token});

/// 현재 Zone에 연결된 CancelToken (DioClient 인터셉터가 요청에 부착).
CancelToken? get ambientCancelToken {
  final token = Zone.current[_cancelTokenZoneKey];
  return token is CancelToken ? token : null;
}
