import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:feple/login/login.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/opensource/s_opensource.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get_utils/src/extensions/string_extensions.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../screen/dialog/d_message.dart';
import '../../common/common.dart';
import '../../common/language/language.dart';
import '../../common/theme/theme_util.dart';
import '../../common/widget/w_mode_switch.dart';

class MenuDrawer extends StatefulWidget {
  static const minHeightForScrollView = 380;

  const MenuDrawer({
    super.key,
  });

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Tap(
          onTap: () {
            closeDrawer(context);
          },
          child: Tap(
            onTap: () {},
            child: Container(
              width: 260,
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24)),
                  color: colors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(5, 0),
                    ),
                  ]),
              child: isSmallScreen(context)
                  ? SingleChildScrollView(
                      child: getMenus(context),
                    )
                  : getMenus(context),
            ),
          ),
        ),
      ),
    );
  }

  bool isSmallScreen(BuildContext context) =>
      context.deviceHeight < MenuDrawer.minHeightForScrollView;

  Container getMenus(BuildContext context) {
    final colors = context.appColors;
    return Container(
      constraints: BoxConstraints(minHeight: context.deviceHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer header — solid color, no gradient
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 10, 16),
            decoration: BoxDecoration(
              color: colors.drawerHeaderBg.withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Feple',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textTitle,
                  ),
                ),
                IconButton(
                  icon: Icon(EvaIcons.close, color: colors.textSecondary),
                  onPressed: () {
                    closeDrawer(context);
                  },
                ),
              ],
            ),
          ),
          Divider(color: colors.listDivider, height: 1),
          _MenuWidget(
            'opensource'.tr(),
            icon: Icons.code_rounded,
            onTap: () async {
              Nav.push(const OpensourceScreen());
            },
          ),
          Divider(
              color: colors.listDivider, height: 1, indent: 16, endIndent: 16),
          _MenuWidget(
            'clear_cache'.tr(),
            icon: Icons.cleaning_services_rounded,
            onTap: () async {
              final manager = DefaultCacheManager();
              await manager.emptyCache();
              if (mounted) {
                MessageDialog('clear_cache_done'.tr()).show();
              }
            },
          ),
          Divider(
              color: colors.listDivider, height: 1, indent: 16, endIndent: 16),
          _MenuWidget(
            'customer_service'.tr(),
            icon: Icons.headset_mic_rounded,
            onTap: () async {
              final uri = Uri.parse('https://open.kakao.com/o/guLhbJki');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          Divider(
              color: colors.listDivider, height: 1, indent: 16, endIndent: 16),
          _MenuWidget(
            'logout'.tr(),
            icon: Icons.logout_rounded,
            color: Theme.of(context).colorScheme.error,
            onTap: () async {
              closeDrawer(context);
              await context.read<UserProvider>().logout();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              }
            },
          ),
          Divider(
              color: colors.listDivider, height: 1, indent: 16, endIndent: 16),
          _MenuWidget(
            'delete_account'.tr(),
            icon: Icons.person_remove_rounded,
            color: Theme.of(context).colorScheme.error,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('delete_account'.tr()),
                  content: Text(
                    'delete_account_confirm'.tr(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('cancel'.tr()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      child: Text('delete_account'.tr()),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              final userProvider = context.read<UserProvider>();
              closeDrawer(context);
              try {
                await userProvider.deleteAccount();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('delete_account_error'.tr())),
                  );
                }
                return;
              }
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
          isSmallScreen(context) ? const Height(10) : const EmptyExpanded(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ModeSwitch(
              value: context.isDarkMode,
              onChanged: (value) {
                ThemeUtil.toggleTheme(context);
              },
              height: 30,
              activeThumbImage: Image.asset('$basePath/darkmode/moon.png'),
              inactiveThumbImage: Image.asset('$basePath/darkmode/sun.png'),
              activeThumbColor: Colors.transparent,
              inactiveThumbColor: Colors.transparent,
            ).pOnly(left: 20),
          ),
          const Height(10),
          getLanguageOption(context),
          const Height(10),
          Row(
            children: [
              Expanded(
                child: Tap(
                  child: Container(
                      height: 30,
                      width: 100,
                      padding: const EdgeInsets.only(left: 15),
                      child: '© 2023. Bansook Nam. all rights reserved.'
                          .selectableText
                          .size(10)
                          .color(colors.textSecondary)
                          .makeWithDefaultFont()),
                  onTap: () async {},
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void closeDrawer(BuildContext context) {
    if (Scaffold.of(context).isDrawerOpen) {
      Scaffold.of(context).closeDrawer();
    }
  }

  Widget getLanguageOption(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Tap(
          child: Container(
              padding: const EdgeInsets.only(left: 5, right: 5),
              margin: const EdgeInsets.only(left: 15, right: 20),
              decoration: BoxDecoration(
                  border: Border.all(color: colors.listDivider),
                  borderRadius: BorderRadius.circular(16),
                  color: colors.surface,
                  boxShadow: [context.appShadows.buttonShadowSmall]),
              child: Row(
                children: [
                  const Width(10),
                  DropdownButton<String>(
                    items: [
                      menu(currentLanguage),
                      menu(Language.values
                          .where((element) => element != currentLanguage)
                          .first),
                    ],
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }
                      await context
                          .setLocale(Language.find(value.toLowerCase()).locale);
                    },
                    value: currentLanguage.name.capitalizeFirst,
                    underline: const SizedBox.shrink(),
                    elevation: 1,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ],
              )),
          onTap: () async {},
        ),
      ],
    );
  }

  DropdownMenuItem<String> menu(Language language) {
    final colors = context.appColors;
    return DropdownMenuItem(
      value: language.name.capitalizeFirst,
      child: Row(
        children: [
          flag(language.flagPath),
          const Width(8),
          language.name
              .capitalizeFirst!
              .text
              .color(colors.textTitle)
              .size(12)
              .makeWithDefaultFont(),
        ],
      ),
    );
  }

  Widget flag(String path) {
    return SimpleShadow(
      opacity: 0.5,
      color: Colors.black45,
      offset: const Offset(2, 2),
      sigma: 2,
      child: Image.asset(
        path,
        width: 20,
      ),
    );
  }
}

class _MenuWidget extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Function() onTap;
  final Color? color;

  const _MenuWidget(this.text, {required this.onTap, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final effectiveColor = color ?? colors.activate;
    final textColor = color ?? colors.textTitle;
    return SizedBox(
      height: 55,
      child: Tap(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 20),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: effectiveColor, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                  child: text.text
                      .textStyle(defaultFontStyle())
                      .color(textColor)
                      .size(15)
                      .make()),
            ],
          ),
        ),
      ),
    );
  }
}
