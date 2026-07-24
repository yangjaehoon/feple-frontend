import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 리스트 아이템이 처음 나타날 때 아래에서 페이드인 + 슬라이드업 효과.
/// [index]를 기반으로 stagger 딜레이를 줍니다.
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDuration;
  // 이 위젯에서만 쓰이는 stagger 전용 튜닝 값 — 다른 곳에서 재사용되지
  // 않아 AppDimens로 승격하지 않음
  final Duration staggerDelay;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDuration = AppDimens.animSlow,
    this.staggerDelay = const Duration(milliseconds: 55),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  // 가상화된(lazy) 리스트에서는 스크롤로 항목이 화면에 새로 들어올 때마다
  // State가 다시 생성돼 이 인덱스 미만에서만 애니메이션이 매번 재생된다.
  // FadeTransition은 내부적으로 Opacity(saveLayer)라 이 이상 인덱스까지
  // 매번 재생하면 스크롤 내내 GPU 비용이 반복된다 — 첫 화면 분량만 stagger
  // 효과를 주고 그 이후는 애니메이션 없이 바로 표시한다.
  static const int _animateLimit = 10;

  AnimationController? _controller;
  Animation<double>? _opacity;
  Animation<Offset>? _slide;

  bool get _shouldAnimate => widget.index < _animateLimit;

  @override
  void initState() {
    super.initState();
    if (!_shouldAnimate) return;

    final controller = AnimationController(
      vsync: this,
      duration: widget.baseDuration,
    );
    _controller = controller;

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );

    final delay = widget.staggerDelay * widget.index;
    if (delay == Duration.zero) {
      controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate) return widget.child;
    return FadeTransition(
      opacity: _opacity!,
      child: SlideTransition(
        position: _slide!,
        child: widget.child,
      ),
    );
  }
}
