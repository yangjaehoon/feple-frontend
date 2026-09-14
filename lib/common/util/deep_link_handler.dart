import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:collection/collection.dart';
import 'package:feple/app.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/model/content_type.dart';
import 'package:feple/screen/notification/notification_destination.dart';
import 'package:flutter/foundation.dart';

/// 공유 딥링크(`feple://festival/123`, `feple://post/456`, `feple://artist/789`)를
/// 받아 해당 화면으로 이동시킨다.
///
/// 커스텀 URL 스킴이라 카카오톡 등 메신저에서 링크로 인식되지 않을 수 있고
/// 앱 미설치 시 아무 동작도 하지 않는다(웹 폴백 불가) — 도메인이 생기면
/// Universal/App Links로 교체해야 한다. 라우팅 규칙은 FCM 알림 탭 처리
/// (`FcmNavigationHandler`)와 `resolveContentDestination`을 공유한다.
class DeepLinkHandler {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  /// 앱이 완전히 종료된 상태에서 링크로 처음 열린 경우와 실행 중에 링크를
  /// 탭한 경우 둘 다 처리한다. uriLinkStream이 첫 구독 시 콜드스타트 링크를
  /// 이미 한 번 재생해주므로(app_links 네이티브 구현) getInitialLink()를
  /// 따로 호출하면 같은 링크가 두 번 처리(화면 중복 push)된다 — 호출하지 않는다.
  void init() {
    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) => debugPrint('[DeepLink] 링크 스트림 오류: $e'),
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<void> _handleUri(Uri uri) async {
    final nav = App.navigatorKey.currentState;
    final type = _parseContentType(uri.host);
    final id = uri.pathSegments.isEmpty ? null : int.tryParse(uri.pathSegments.first);
    if (nav == null || type == null || id == null) {
      debugPrint('[DeepLink] 처리 불가한 링크: $uri');
      return;
    }

    try {
      final screen = await resolveContentDestination(type, id);
      unawaited(nav.push(SlideRoute(builder: (_) => screen)));
    } catch (e) {
      debugPrint('[DeepLink] 이동 실패: $e');
    }
  }

  ContentType? _parseContentType(String host) => ContentType.values
      .firstWhereOrNull((type) => type.pathSegment == host);
}
