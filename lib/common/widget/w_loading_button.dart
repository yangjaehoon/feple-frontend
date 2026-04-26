import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 로딩/완료 상태를 내장한 FilledButton.
/// [isLoading] true → 스피너, [isSuccess] true → 체크마크 애니메이션
class LoadingButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final IconData? icon;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;

  const LoadingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.icon,
    this.backgroundColor,
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
      duration: const Duration(milliseconds: 350),
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
    final successColor = const Color(0xFF00C896);

    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: widget.isSuccess
              ? successColor
              : (widget.isLoading ? bg.withValues(alpha: 0.6) : bg),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: FilledButton(
          onPressed: (widget.isLoading || widget.isSuccess)
              ? null
              : (widget.onPressed == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      widget.onPressed!();
                    }),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
          child: _buildChild(),
        ),
      ),
    );
  }

  Widget _buildChild() {
    if (widget.isSuccess) {
      return ScaleTransition(
        scale: _checkScale,
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
      );
    }
    if (widget.isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
