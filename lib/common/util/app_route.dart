import 'package:flutter/material.dart';

/// 오른쪽에서 슬라이드 인 하는 페이지 전환 라우트.
/// MaterialPageRoute의 Android 기본 동작(아래에서 위로) 대신
/// iOS/Toss/Baemin 스타일의 수평 슬라이드를 모든 플랫폼에 적용합니다.
class SlideRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  SlideRoute({required this.builder, super.settings})
      : super(
          pageBuilder: (context, _, __) => builder(context),
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final slideTween = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            );
            // 현재 화면은 약간 왼쪽으로 밀려나는 효과
            final secondarySlideTween = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.25, 0.0),
            );
            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: secondarySlideTween.animate(secondaryCurved),
              child: SlideTransition(
                position: slideTween.animate(curved),
                child: child,
              ),
            );
          },
        );
}
