import 'dart:async';

import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

/// id로 상세 데이터를 조회해 화면으로 이동하는 공통 흐름: 로딩 표시 → fetch →
/// push → 실패 시 로그만 남기고 조용히 무시 → 로딩 해제.
/// [awaitNavigation]이 true(기본값)면 화면에서 돌아올 때까지 로딩 상태를
/// 유지하고, false면 push만 발생시키고 fetch 완료 직후 로딩을 해제한다.
Future<void> navigateAfterFetch<T>(
  BuildContext context, {
  required Future<T> Function() fetch,
  required Widget Function(T data) builder,
  required void Function(bool loading) setLoading,
  required String errorTag,
  bool awaitNavigation = true,
}) async {
  setLoading(true);
  try {
    final data = await fetch();
    if (!context.mounted) return;
    final push = Navigator.push(
      context,
      SlideRoute(builder: (_) => builder(data)),
    );
    if (awaitNavigation) {
      await push;
    } else {
      unawaited(push);
    }
  } catch (e) {
    debugPrint('[$errorTag] 이동 실패: $e');
  } finally {
    setLoading(false);
  }
}
