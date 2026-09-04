import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_guest_login_prompt.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 계정 기반 탭(홈 대시보드·커뮤니티)처럼 게스트에게는 의미가 없는 화면을 감싸
/// 로그인 상태가 아니면 로그인 유도 화면을 대신 보여준다. 페스티벌 목록·검색·
/// 마이페이지처럼 게스트도 볼 게 있는 화면은 이 위젯으로 감싸지 않는다
/// (Apple 가이드라인 5.1.1(v) — 비계정 기능은 로그인 없이 접근 가능해야 함).
class RequireLoginGate extends StatelessWidget {
  final Widget child;
  final IconData icon;
  final String titleKey;
  final String messageKey;

  const RequireLoginGate({
    super.key,
    required this.child,
    required this.icon,
    required this.titleKey,
    required this.messageKey,
  });

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<UserProvider, bool>((p) => p.user != null);
    return isLoggedIn
        ? child
        : _GuestPrompt(icon: icon, titleKey: titleKey, messageKey: messageKey);
  }
}

class _GuestPrompt extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String messageKey;

  const _GuestPrompt({
    required this.icon,
    required this.titleKey,
    required this.messageKey,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appColors.backgroundMain,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: GuestLoginPrompt(icon: icon, titleKey: titleKey, messageKey: messageKey),
        ),
      ),
    );
  }
}
