import 'package:flutter/material.dart';

/// 빈 상태/에러 상태에서도 [RefreshIndicator]의 pull-to-refresh 제스처가
/// 동작하도록 콘텐츠를 뷰포트 전체 높이로 채우는 스크롤 가능한 래퍼.
class RefreshableCenter extends StatelessWidget {
  final Widget child;

  const RefreshableCenter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: child),
        ),
      ),
    );
  }
}
