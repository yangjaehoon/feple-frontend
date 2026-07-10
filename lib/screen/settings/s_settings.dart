import 'package:feple/common/common.dart';
import 'package:feple/common/language/language.dart';
import 'package:feple/common/theme/theme_util.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/w_edit_profile.dart';
import 'package:feple/screen/opensource/s_opensource.dart';
import 'package:feple/screen/settings/s_notification_settings.dart';
import 'package:feple/screen/settings/s_blocked_users.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/screen/onboarding/s_onboarding.dart';
import 'package:flutter/foundation.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with NavigationGuard {
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
    // logout()이 notifyListeners → Consumer가 home을 LoginScreen으로 교체.
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
    try {
      await Future.wait([
        DefaultCacheManager().emptyCache(),
        sl<FestivalCacheService>().clearAll(),
      ]);
      if (!mounted) return;
      context.showSuccessSnackbar('clear_cache_done'.tr());
    } catch (e) {
      debugPrint('clear cache error: $e');
      if (mounted) context.showErrorSnackbar('clear_cache_failed'.tr());
    } finally {
      if (mounted) setState(() => _clearingCache = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // Subscribe to locale changes so labels re-translate immediately
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
      _SectionHeader(label: 'settings_account'.tr()),
      _SettingsItem(
        icon: Icons.edit_rounded,
        label: 'edit_profile'.tr(),
        onTap: () => guardedNavigate(() =>
            Navigator.push(context, SlideRoute(builder: (_) => const EditProfileWidget()))),
      ),
      const _ItemDivider(),
      _SettingsItem(
        icon: Icons.block_rounded,
        label: 'blocked_users'.tr(),
        onTap: () => guardedNavigate(() =>
            Navigator.push(context, SlideRoute(builder: (_) => const BlockedUsersScreen()))),
      ),
      const _ItemDivider(),
      // 로그아웃은 자주 쓰는 되돌릴 수 있는 행동이라 중립 스타일 유지 —
      // 회원탈퇴(영구 삭제)와 동일한 빨간색을 쓰면 위험도 구분이 안 됨
      _SettingsItem(
        icon: Icons.logout_rounded,
        label: 'logout'.tr(),
        onTap: _logout,
      ),
      const _ItemDivider(),
      _SettingsItem(
        icon: Icons.person_remove_rounded,
        label: 'delete_account'.tr(),
        onTap: _deleteAccount,
        isDestructive: true,
      ),
    ];
  }

  List<Widget> _buildAppSection(AbstractThemeColors colors, bool isDark) {
    return [
      _SectionHeader(label: 'settings_app'.tr()),
      _SettingsItem(
        icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        label: 'dark_mode'.tr(),
        trailing: Switch(
          value: isDark,
          onChanged: (_) => ThemeUtil.toggleTheme(context),
          activeThumbColor: colors.activate,
        ),
      ),
      const _ItemDivider(),
      const _LanguageItem(),
      const _ItemDivider(),
      _SettingsItem(
        icon: Icons.cleaning_services_rounded,
        label: 'clear_cache'.tr(),
        trailing: _clearingCache
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: colors.activate),
              )
            : null,
        onTap: _clearingCache ? null : _clearCache,
      ),
      const _ItemDivider(),
      _SettingsItem(
        icon: Icons.notifications_rounded,
        label: 'notif_settings'.tr(),
        onTap: () => guardedNavigate(() =>
            Navigator.push(context, SlideRoute(builder: (_) => const NotificationSettingsScreen()))),
      ),
    ];
  }

  List<Widget> _buildSupportSection(AbstractThemeColors colors) {
    return [
      _SectionHeader(label: 'settings_support'.tr()),
      _SettingsItem(
        icon: Icons.headset_mic_rounded,
        label: 'customer_service'.tr(),
        onTap: () async {
          final uri = Uri.parse('https://open.kakao.com/o/guLhbJki');
          try {
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!launched && mounted) context.showErrorSnackbar('link_open_failed'.tr());
          } catch (_) {
            if (mounted) context.showErrorSnackbar('link_open_failed'.tr());
          }
        },
      ),
      const _ItemDivider(),
      _SettingsItem(
        icon: Icons.privacy_tip_rounded,
        label: 'privacy_policy'.tr(),
        onTap: () async {
          final uri = Uri.parse('https://yangjae.notion.site/feple-privacy?source=copy_link');
          try {
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!launched && mounted) context.showErrorSnackbar('link_open_failed'.tr());
          } catch (_) {
            if (mounted) context.showErrorSnackbar('link_open_failed'.tr());
          }
        },
      ),
      const _ItemDivider(),
      _SettingsItem(
        icon: Icons.code_rounded,
        label: 'opensource'.tr(),
        onTap: () => guardedNavigate(() =>
            Navigator.push(context, SlideRoute(builder: (_) => const OpensourceScreen()))),
      ),
      const _ItemDivider(),
      _VersionItem(version: _appVersion),
    ];
  }

  List<Widget> _buildDevSection(AbstractThemeColors colors) {
    return [
      const _SectionHeader(label: 'DEV'),
      _SettingsItem(
        icon: Icons.replay_rounded,
        label: 'onboarding_replay'.tr(),
        onTap: _resetOnboarding,
      ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: AppDimens.fontSizeXxs,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ItemDivider extends StatelessWidget {
  const _ItemDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 50,
      color: context.appColors.listDivider,
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconColor = isDestructive
        ? colors.error
        : colors.activate;
    final textColor = isDestructive
        ? colors.error
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

class _LanguageItem extends StatefulWidget {
  const _LanguageItem();

  @override
  State<_LanguageItem> createState() => _LanguageItemState();
}

class _LanguageItemState extends State<_LanguageItem> {
  late Language _selected;

  @override
  void initState() {
    super.initState();
    _selected = currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
                fontSize: AppDimens.fontSizeLg,
                fontWeight: FontWeight.w500,
                color: colors.textTitle,
              ),
            ),
          ),
          _buildLanguageDropdown(context, colors),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(BuildContext context, AbstractThemeColors colors) {
    return DropdownMenu<Language>(
      initialSelection: _selected,
      enableFilter: false,
      requestFocusOnTap: false,
      leadingIcon: Image.asset(_selected.flagPath, width: 16, height: 16),
      textStyle: TextStyle(
        fontSize: AppDimens.fontSizeMd,
        fontWeight: FontWeight.w600,
        color: colors.textTitle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.shapeInput),
          borderSide: BorderSide(color: colors.listDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.shapeInput),
          borderSide: BorderSide(color: colors.listDivider),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.shapeDialog),
          ),
        ),
      ),
      dropdownMenuEntries: Language.values.map((l) {
        return DropdownMenuEntry<Language>(
          value: l,
          label: l.name[0].toUpperCase() + l.name.substring(1),
          leadingIcon: Image.asset(l.flagPath, width: 16, height: 16),
        );
      }).toList(),
      onSelected: (value) async {
        if (value == null) return;
        setState(() => _selected = value);
        await context.setLocale(value.locale);
      },
    );
  }
}

class _VersionItem extends StatelessWidget {
  final String version;

  const _VersionItem({required this.version});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
                fontSize: AppDimens.fontSizeLg,
                fontWeight: FontWeight.w500,
                color: colors.textTitle,
              ),
            ),
          ),
          Text(
            version.isEmpty ? '-' : 'v$version',
            style: TextStyle(
              fontSize: AppDimens.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}


