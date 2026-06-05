import 'package:feple/common/common.dart';
import 'package:feple/common/language/language.dart';
import 'package:feple/common/theme/theme_util.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/w_edit_profile.dart';
import 'package:feple/screen/opensource/s_opensource.dart';
import 'package:feple/screen/settings/s_notification_settings.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/screen/onboarding/s_onboarding.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get_utils/src/extensions/string_extensions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _clearingCache = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'logout'.tr(),
      content: 'logout_confirm'.tr(),
      confirmLabel: 'logout'.tr(),
    );
    if (!confirmed || !mounted) return;
    // rootNavigator를 await 전에 캡처 — logout 후 위젯이 unmount되어 context 사용 불가
    final rootNav = Navigator.of(context, rootNavigator: true);
    final userProvider = context.read<UserProvider>();
    try {
      await userProvider.logout();
    } catch (_) {}
    // logout()이 notifyListeners → Consumer가 home을 LoginPage로 교체.
    // rootNavigator에 남은 extra 라우트(rootNavigator:true로 push된 것들)만 정리.
    rootNav.popUntil((route) => route.isFirst);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'delete_account'.tr(),
      content: 'delete_account_confirm'.tr(),
      confirmLabel: 'delete_account'.tr(),
    );
    if (!confirmed || !mounted) return;
    final rootNav = Navigator.of(context, rootNavigator: true);
    final userProvider = context.read<UserProvider>();
    try {
      await userProvider.deleteAccount();
    } catch (_) {
      if (mounted) context.showErrorSnackbar('delete_account_error'.tr());
      return;
    }
    rootNav.popUntil((route) => route.isFirst);
  }

  Future<void> _resetOnboarding() async {
    await Prefs.onboardingCompleted.set(false);
    if (!mounted) return;
    final rootNav = Navigator.of(context, rootNavigator: true);
    rootNav.push(
      SlideRoute(
        builder: (_) => OnboardingScreen(
          onComplete: () => rootNav.popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    setState(() => _clearingCache = true);
    await DefaultCacheManager().emptyCache();
    if (!mounted) return;
    setState(() => _clearingCache = false);
    context.showSuccessSnackbar('clear_cache_done'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.themeType == CustomTheme.dark;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: 'settings'.tr()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                ..._buildAccountSection(colors),
                ..._buildAppSection(colors, isDark),
                ..._buildSupportSection(colors),
                if (kDebugMode) ..._buildDevSection(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccountSection(AbstractThemeColors colors) {
    return [
      _SectionHeader(label: 'settings_account'.tr(), colors: colors),
      _SettingsItem(
        icon: Icons.edit_rounded,
        label: 'edit_profile'.tr(),
        colors: colors,
        onTap: () => Navigator.push(
          context,
          SlideRoute(builder: (_) => const EditProfileWidget()),
        ),
      ),
      _ItemDivider(colors: colors),
      _SettingsItem(
        icon: Icons.logout_rounded,
        label: 'logout'.tr(),
        colors: colors,
        onTap: _logout,
        isDestructive: true,
      ),
      _ItemDivider(colors: colors),
      _SettingsItem(
        icon: Icons.person_remove_rounded,
        label: 'delete_account'.tr(),
        colors: colors,
        onTap: _deleteAccount,
        isDestructive: true,
      ),
    ];
  }

  List<Widget> _buildAppSection(AbstractThemeColors colors, bool isDark) {
    return [
      _SectionHeader(label: 'settings_app'.tr(), colors: colors),
      _SettingsItem(
        icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        label: 'dark_mode'.tr(),
        colors: colors,
        trailing: Switch(
          value: isDark,
          onChanged: (_) => ThemeUtil.toggleTheme(context),
          activeThumbColor: colors.activate,
        ),
      ),
      _ItemDivider(colors: colors),
      _LanguageItem(colors: colors),
      _ItemDivider(colors: colors),
      _SettingsItem(
        icon: Icons.cleaning_services_rounded,
        label: 'clear_cache'.tr(),
        colors: colors,
        trailing: _clearingCache
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: colors.activate),
              )
            : null,
        onTap: _clearingCache ? null : _clearCache,
      ),
      _ItemDivider(colors: colors),
      _SettingsItem(
        icon: Icons.notifications_rounded,
        label: 'notif_settings'.tr(),
        colors: colors,
        onTap: () => Navigator.push(
          context,
          SlideRoute(builder: (_) => const NotificationSettingsScreen()),
        ),
      ),
    ];
  }

  List<Widget> _buildSupportSection(AbstractThemeColors colors) {
    return [
      _SectionHeader(label: 'settings_support'.tr(), colors: colors),
      _SettingsItem(
        icon: Icons.headset_mic_rounded,
        label: 'customer_service'.tr(),
        colors: colors,
        onTap: () async {
          final uri = Uri.parse('https://open.kakao.com/o/guLhbJki');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
      _ItemDivider(colors: colors),
      _SettingsItem(
        icon: Icons.privacy_tip_rounded,
        label: 'privacy_policy'.tr(),
        colors: colors,
        onTap: () async {
          final uri = Uri.parse('https://yangjae.notion.site/feple-privacy?source=copy_link');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
      _ItemDivider(colors: colors),
      _SettingsItem(
        icon: Icons.code_rounded,
        label: 'opensource'.tr(),
        colors: colors,
        onTap: () => Navigator.push(
          context,
          SlideRoute(builder: (_) => const OpensourceScreen()),
        ),
      ),
      _ItemDivider(colors: colors),
      _VersionItem(version: _appVersion, colors: colors),
    ];
  }

  List<Widget> _buildDevSection(AbstractThemeColors colors) {
    return [
      _SectionHeader(label: 'DEV', colors: colors),
      _SettingsItem(
        icon: Icons.replay_rounded,
        label: 'onboarding_replay'.tr(),
        colors: colors,
        onTap: _resetOnboarding,
      ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final AbstractThemeColors colors;

  const _SectionHeader({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ItemDivider extends StatelessWidget {
  final AbstractThemeColors colors;

  const _ItemDivider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 50,
      color: colors.listDivider,
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final AbstractThemeColors colors;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.colors,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive
        ? Theme.of(context).colorScheme.error
        : colors.activate;
    final textColor = isDestructive
        ? Theme.of(context).colorScheme.error
        : colors.textTitle;

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
                  fontSize: 15,
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

class _LanguageItem extends StatelessWidget {
  final AbstractThemeColors colors;

  const _LanguageItem({required this.colors});

  @override
  Widget build(BuildContext context) {
    final lang = currentLanguage;
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.language_rounded, size: 20, color: colors.activate),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'language'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textTitle,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: lang.name.capitalizeFirst,
              dropdownColor: colors.surface,
              borderRadius: BorderRadius.circular(12),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textTitle,
              ),
              items: Language.values.map((l) {
                return DropdownMenuItem(
                  value: l.name.capitalizeFirst,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(l.flagPath, width: 20),
                      const SizedBox(width: 8),
                      Text(
                        l.name.capitalizeFirst!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textTitle,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) async {
                if (value == null) return;
                await context
                    .setLocale(Language.find(value.toLowerCase()).locale);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionItem extends StatelessWidget {
  final String version;
  final AbstractThemeColors colors;

  const _VersionItem({required this.version, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: colors.activate),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'app_version'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textTitle,
              ),
            ),
          ),
          Text(
            version.isEmpty ? '-' : 'v$version',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}


