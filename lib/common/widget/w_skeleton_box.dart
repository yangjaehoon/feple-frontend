import 'package:feple/common/constant/app_colors.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 로딩 중 콘텐츠 모양을 흉내낸 shimmer 애니메이션 박스.
/// width를 생략하면 부모 너비를 꽉 채웁니다.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDimens.animSkeleton,
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 1.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base      = isDark ? AppColors.skeletonBaseDark      : AppColors.skeletonBaseLight;
    final highlight = isDark ? AppColors.skeletonHighlightDark : AppColors.skeletonHighlightLight;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, _) {
        final shimmerValue = _shimmer.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(shimmerValue - 1, 0),
              end: Alignment(shimmerValue + 1, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}
