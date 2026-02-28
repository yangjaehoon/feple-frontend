import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:fast_app_base/screen/opensource/s_opensource.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get_utils/src/extensions/string_extensions.dart';
import 'package:simple_shadow/simple_shadow.dart';

import '../../../screen/dialog/d_message.dart';
import '../../common/common.dart';
import '../../common/language/language.dart';
import '../../common/theme/theme_util.dart';
import '../../common/widget/w_mode_switch.dart';

class MenuDrawer extends StatefulWidget {
  static const minHeightForScrollView = 380;

  const MenuDrawer({
    Key? key,
  }) : super(key: key);

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
                      topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
                  color: colors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow.withOpacity(0.1),
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
              color: colors.drawerHeaderBg.withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fill your Festival ✨',
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
          Divider(color: colors.listDivider, height: 1, indent: 16, endIndent: 16),
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
          Divider(color: colors.listDivider, height: 1, indent: 16, endIndent: 16),
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
                        menu(Language.values.where((element) => element != currentLanguage).first),
                      ],
                      onChanged: (value) async {
                        if (value == null) {
                          return;
                        }
                        await context.setLocale(Language.find(value.toLowerCase()).locale);
                      },
                      value: describeEnum(currentLanguage).capitalizeFirst,
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
      value: describeEnum(language).capitalizeFirst,
      child: Row(
        children: [
          flag(language.flagPath),
          const Width(8),
          describeEnum(language)
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
      color: Colors.grey,
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

  const _MenuWidget(this.text, {Key? key, required this.onTap, this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 55,
      child: Tap(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 20),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: colors.activate, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                  child: text.text
                      .textStyle(defaultFontStyle())
                      .color(colors.textTitle)
                      .size(15)
                      .make()),
            ],
          ),
        ),
      ),
    );
  }
}
