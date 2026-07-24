import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 누를 때 살짝 축소되는 스케일 애니메이션 래퍼.
/// GestureDetector를 대체하거나 감쌀 수 있습니다.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  /// 스크린리더용 설명. 시각적으로만(색상/굵기 등) 구분되는 상태를
  /// 함께 전달해야 할 때 지정 (예: 알림 카드의 읽음/안읽음 상태).
  final String? semanticsLabel;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.duration = AppDimens.animTapFeedback,
    this.semanticsLabel,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scaleAnim, child: widget.child),
    );
    if (widget.semanticsLabel == null) return gesture;
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticsLabel,
      child: gesture,
    );
  }
}
