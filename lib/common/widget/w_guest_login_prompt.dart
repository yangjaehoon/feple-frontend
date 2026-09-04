import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/login_gate.dart';
import 'package:flutter/material.dart';

/// 게스트에게 "로그인하면 이런 걸 할 수 있어요" 안내 + 로그인 버튼을 보여주는
/// 공용 콘텐츠 블록. 전체 화면(RequireLoginGate)이든 카드(게스트 마이페이지)든
/// 바깥 컨테이너만 다르게 감싸 재사용한다.
class GuestLoginPrompt extends StatelessWidget {
  final IconData icon;
  final String messageKey;

  const GuestLoginPrompt({
    super.key,
    required this.icon,
    required this.messageKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 44, color: colors.activate),
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
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => openLoginScreen(context),
            style: FilledButton.styleFrom(
              backgroundColor: colors.activate,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.shapeButton),
              ),
            ),
            child: Text('login'.tr()),
          ),
        ),
      ],
    );
  }
}
