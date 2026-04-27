import 'package:flutter/material.dart';

/// 리스트 아이템이 처음 나타날 때 아래에서 페이드인 + 슬라이드업 효과.
/// [index]를 기반으로 stagger 딜레이를 줍니다.
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDuration;
  final Duration staggerDelay;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDuration = const Duration(milliseconds: 350),
    this.staggerDelay = const Duration(milliseconds: 55),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.baseDuration,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // 최대 10개까지만 stagger — 그 이상은 즉시 표시
    final delay = widget.index < 10
        ? widget.staggerDelay * widget.index
        : Duration.zero;

    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
