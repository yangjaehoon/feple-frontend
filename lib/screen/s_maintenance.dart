import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_blocking_notice.dart';
import 'package:flutter/material.dart';

/// 서버 점검 모드일 때 앱 진입 대신 노출하는 화면.
/// [onRetry]는 설정을 다시 조회한다 — 점검이 끝났으면 정상 진입으로 넘어간다.
class MaintenanceScreen extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const MaintenanceScreen({super.key, required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    final serverMessage = message?.trim();
    return BlockingNotice(
      icon: Icons.build_outlined,
      title: 'maintenance_title'.tr(),
      message: (serverMessage == null || serverMessage.isEmpty)
          ? 'maintenance_message'.tr()
          : serverMessage,
      primaryLabel: 'maintenance_retry'.tr(),
      onPrimary: onRetry,
    );
  }
}
