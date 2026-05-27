import 'package:feple/common/common.dart';
import 'package:feple/common/language/language.dart';
import 'package:feple/common/theme/theme_util.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/login/s_login.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/w_edit_profile.dart';
import 'package:feple/screen/opensource/s_opensource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get_utils/src/extensions/string_extensions.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _clearingCache = false;

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'logout'.tr(),
      content: 'logout_confirm'.tr(),
      confirmLabel: 'logout'.tr(),
    );
    if (!confirmed || !mounted) return;
    final userProvider = context.read<UserProvider>();
    try {
      await userProvider.logout();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      SlideRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'delete_account'.tr(),
      content: 'delete_account_confirm'.tr(),
      confirmLabel: 'delete_account'.tr(),
    );
    if (!confirmed || !mounted) return;
    final userProvider = context.read<UserProvider>();
    try {
      await userProvider.deleteAccount();
    } catch (_) {
      if (mounted) context.showErrorSnackbar('delete_account_error'.tr());
      return;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      SlideRoute(builder: (_) => const LoginPage()),
      (_) => false,
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
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colors.activate),
                        )
                      : null,
                  onTap: _clearingCache ? null : _clearCache,
                ),
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
                  icon: Icons.code_rounded,
                  label: 'opensource'.tr(),
                  colors: colors,
                  onTap: () => Navigator.push(
                    context,
                    SlideRoute(builder: (_) => const OpensourceScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
