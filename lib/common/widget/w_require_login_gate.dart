import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/login/s_login.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 계정 기반 탭(홈 대시보드·커뮤니티·마이페이지)처럼 게스트에게는 의미가 없는
/// 화면을 감싸 로그인 상태가 아니면 로그인 유도 화면을 대신 보여준다.
/// 페스티벌 목록·검색처럼 비계정 콘텐츠는 이 위젯으로 감싸지 않는다
/// (Apple 가이드라인 5.1.1(v) — 비계정 기능은 로그인 없이 접근 가능해야 함).
class RequireLoginGate extends StatelessWidget {
  final Widget child;
  final IconData icon;
  final String messageKey;

  const RequireLoginGate({
    super.key,
    required this.child,
    required this.icon,
    required this.messageKey,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<UserProvider, bool>((p) => p.user != null);
    return isLoggedIn ? child : _GuestPrompt(icon: icon, messageKey: messageKey);
  }
}

class _GuestPrompt extends StatelessWidget {
  final IconData icon;
  final String messageKey;

  const _GuestPrompt({required this.icon, required this.messageKey});

  void _openLogin(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ColoredBox(
      color: colors.backgroundMain,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: colors.textSecondary.withValues(alpha: 0.6)),
              const SizedBox(height: AppDimens.space16),
              Text(
                messageKey.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppDimens.space20),
              FilledButton(
                onPressed: () => _openLogin(context),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.activate,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.shapeButton),
                  ),
                ),
                child: Text('login'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
