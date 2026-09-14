import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

/// OS 권한이 꺼져 있을 때 아이콘 + 설명 + "설정으로 이동" 버튼을 보여주는
/// 공용 콘텐츠. 배경·여백·모서리 등 컨테이너 스타일은 호출부에서 감싸 결정한다
/// (알림 설정 화면의 카드형 배너와 부스 지도의 얇은 오버레이 바가 서로 다른
/// 컨테이너 스타일을 쓰기 때문).
class PermissionOffBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onOpenSettings;
  final double fontSize;

  const PermissionOffBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.onOpenSettings,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(icon, color: colors.error, size: fontSize + 9),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: fontSize, color: colors.textSecondary, height: 1.4),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onOpenSettings,
          style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
          child: Text(
            'perm_settings_open'.tr(),
            style: TextStyle(fontSize: fontSize, color: colors.activate, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
