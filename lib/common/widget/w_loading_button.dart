import 'package:feple/common/constant/app_colors.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 로딩/완료 상태를 내장한 FilledButton.
/// [isLoading] true → 스피너, [isSuccess] true → 체크마크 애니메이션
class LoadingButton extends StatefulWidget {
  final String label;
  final Widget? child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double borderRadius;

  const LoadingButton({
    super.key,
    this.label = '',
    this.child,
    this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 52,
    this.borderRadius = 16,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: AppDimens.animSlow,
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(LoadingButton old) {
    super.didUpdateWidget(old);
    if (widget.isSuccess && !old.isSuccess) {
      _checkController.forward(from: 0);
    } else if (!widget.isSuccess) {
      _checkController.reset();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Theme.of(context).colorScheme.primary;
    final fg = widget.foregroundColor ?? Theme.of(context).colorScheme.onPrimary;
    const successColor = AppColors.successGreen;
    // onPressed가 null인 비활성 상태도 흐리게 표시 — 그렇지 않으면 활성 버튼과
    // 색이 동일해 탭이 씹히는 것처럼 보임 (isLoading과 동일한 dimming 재사용)
    final isDisabled = !widget.isLoading && !widget.isSuccess && widget.onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: AnimatedContainer(
        duration: AppDimens.animFast,
        decoration: BoxDecoration(
          color: widget.isSuccess
              ? successColor
              : (widget.isLoading || isDisabled ? bg.withValues(alpha: 0.6) : bg),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: FilledButton(
          onPressed: _resolvedOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: fg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
          child: _buildChild(fg),
        ),
      ),
    );
  }

  VoidCallback? get _resolvedOnPressed {
    if (widget.isLoading || widget.isSuccess) return null;
    if (widget.onPressed == null) return null;
    return () {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    };
  }

  Widget _buildChild(Color fgColor) {
    if (widget.isSuccess) {
      return ScaleTransition(
        scale: _checkScale,
        child: Icon(Icons.check_rounded, color: fgColor, size: 26),
      );
    }
    // 로딩 중에도 라벨을 투명하게 유지해 버튼 너비를 그대로 보존한다 — 스피너만
    // 그리면 라벨보다 좁아져, IntrinsicWidth로 크기가 정해지는 부모(닉네임
    // 중복확인 버튼 등)에서 옆 위젯이 순간적으로 늘어났다 줄어드는 깜빡임 발생.
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: widget.isLoading ? 0 : 1,
          child: widget.child ?? _buildLabel(),
        ),
        if (widget.isLoading)
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fgColor),
          ),
      ],
    );
  }

  Widget _buildLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18),
          const SizedBox(width: AppDimens.space8),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: AppDimens.fontSizeXl,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
