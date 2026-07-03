import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:flutter/material.dart';

/// 시스템 권한 요청 전 사용자에게 목적을 설명하는 바텀시트.
/// true → 허용 버튼, false → 나중에 또는 바텀시트 닫힘
class PermissionRationale {
  static Future<bool> showNotification(BuildContext context) =>
      _show(context, _notification);

  static Future<bool> showLocation(BuildContext context) =>
      _show(context, _location);

  static Future<bool> _show(BuildContext context, _Config config) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PermissionSheet(config: config),
    );
    return result ?? false;
  }

  static const _notification = _Config(
    icon: Icons.notifications_rounded,
    titleKey: 'perm_notif_title',
    descKey: 'perm_notif_desc',
    allowKey: 'perm_notif_allow',
  );

  static const _location = _Config(
    icon: Icons.location_on_rounded,
    titleKey: 'perm_loc_title',
    descKey: 'perm_loc_desc',
    allowKey: 'perm_loc_allow',
  );
}

class _Config {
  final IconData icon;
  final String titleKey;
  final String descKey;
  final String allowKey;

  const _Config({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.allowKey,
  });
}

class _PermissionSheet extends StatelessWidget {
  final _Config config;
  const _PermissionSheet({required this.config});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const BottomSheetHandle(),
              const SizedBox(height: 32),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: colors.activate.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, size: 38, color: colors.activate),
              ),
              const SizedBox(height: 20),
              Text(
                config.titleKey.tr(),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeTitle,
                  fontWeight: FontWeight.w700,
                  color: colors.textTitle,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                config.descKey.tr(),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  color: colors.textSecondary,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              LoadingButton(
                label: config.allowKey.tr(),
                onPressed: () => Navigator.of(context).pop(true),
                backgroundColor: colors.activate,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(
                  'perm_later'.tr(),
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeMd,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
