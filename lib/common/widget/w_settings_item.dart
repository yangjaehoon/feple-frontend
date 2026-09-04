import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/store_links.dart';
import 'package:feple/common/util/external_link.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 설정류 화면(설정/알림 설정 등)에서 반복되는 한 줄 항목
/// (아이콘 + 라벨 + trailing) — 탭 가능하면 [onTap], 스위치 등 커스텀
/// trailing이 필요하면 [trailing]을 넘긴다.
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconColor = isDestructive ? colors.error : colors.activate;
    final textColor = isDestructive ? colors.error : colors.textTitle;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: colors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeLg,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class SettingsItemDivider extends StatelessWidget {
  const SettingsItemDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 50,
      color: context.appColors.listDivider,
    );
  }
}

/// 공지사항·고객센터·이용약관·개인정보처리방침 4개 항목(사이 구분선 포함).
/// 계정이 없어도 필요한 링크라 설정 화면과 게스트 마이페이지가 공유한다.
/// [onNotices]는 공지 목록 화면으로의 이동(각 화면의 guardedNavigate 등)을 넘긴다.
List<Widget> supportLinkItems(
  BuildContext context, {
  required VoidCallback onNotices,
}) {
  return [
    SettingsItem(
      icon: Icons.campaign_outlined,
      label: 'notices'.tr(),
      onTap: onNotices,
    ),
    const SettingsItemDivider(),
    SettingsItem(
      icon: Icons.headset_mic_rounded,
      label: 'customer_service'.tr(),
      onTap: () => openExternalUrl(context, kCustomerServiceUrl),
    ),
    const SettingsItemDivider(),
    SettingsItem(
      icon: Icons.description_outlined,
      label: 'terms_of_service'.tr(),
      onTap: () => openExternalUrl(context, kTermsOfServiceUrl),
    ),
    const SettingsItemDivider(),
    SettingsItem(
      icon: Icons.privacy_tip_rounded,
      label: 'privacy_policy'.tr(),
      onTap: () => openExternalUrl(context, kPrivacyPolicyUrl),
    ),
  ];
}

/// 앱 버전을 표시하는 설정 항목. `package_info_plus`로 직접 버전을 읽어
/// 우측에 `v{버전}`(없으면 `-`)을 보여준다. 설정 화면과 게스트 마이페이지가 공유한다.
/// Future는 initState에서 한 번만 만든다 — build에서 만들면 리빌드마다 `-`로 깜빡인다.
class AppVersionRow extends StatefulWidget {
  const AppVersionRow({super.key});

  @override
  State<AppVersionRow> createState() => _AppVersionRowState();
}

class _AppVersionRowState extends State<AppVersionRow> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        return SettingsItem(
          icon: Icons.info_outline_rounded,
          label: 'app_version'.tr(),
          trailing: Text(
            version.isEmpty ? '-' : 'v$version',
            style: TextStyle(
              fontSize: AppDimens.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
