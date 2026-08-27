import 'dart:io';

import 'package:feple/common/util/forced_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 당겨서 새로고침 가능한 단일 컨텐츠 스크롤 뷰.
/// iOS에서는 [CupertinoSliverRefreshControl]로 네이티브 스타일 인디케이터를,
/// 그 외 플랫폼에서는 기존 [RefreshIndicator]를 사용한다.
class AdaptiveRefreshView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;
  final Color? indicatorColor;

  const AdaptiveRefreshView({
    super.key,
    required this.onRefresh,
    required this.child,
    this.controller,
    this.padding = EdgeInsets.zero,
    this.indicatorColor,
  });

  // 당겨서 새로고침은 사용자가 명시적으로 최신화를 요청한 것이므로
  // SWR 캐시를 건너뛰고 실제 네트워크 요청을 강제한다.
  Future<void> _onRefresh() => withForcedRefresh(onRefresh);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CustomScrollView(
        controller: controller,
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: _onRefresh),
          SliverPadding(padding: padding, sliver: SliverToBoxAdapter(child: child)),
        ],
      );
    }
    return RefreshIndicator(
      color: indicatorColor,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: child,
      ),
    );
  }
}
