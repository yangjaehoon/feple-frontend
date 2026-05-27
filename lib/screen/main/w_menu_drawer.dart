import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:feple/screen/main/w_menu_language_selector.dart';
import 'package:flutter/material.dart';

import '../../common/common.dart';
import '../../common/theme/theme_util.dart';
import '../../common/widget/w_mode_switch.dart';

class MenuDrawer extends StatefulWidget {
  static const minHeightForScrollView = 380;

  const MenuDrawer({super.key});

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
          onTap: () => closeDrawer(context),
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
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          onPressed: () => closeDrawer(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: colors.listDivider, height: 1),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ModeSwitch(
                      value: context.isDarkMode,
                      onChanged: (value) => ThemeUtil.toggleTheme(context),
                      height: 30,
                      activeThumbImage: Image.asset('$basePath/darkmode/moon.png'),
                      inactiveThumbImage: Image.asset('$basePath/darkmode/sun.png'),
                      activeThumbColor: Colors.transparent,
                      inactiveThumbColor: Colors.transparent,
                    ).pOnly(left: 20),
                  ),
                  const Height(10),
                  const MenuLanguageSelector(),
                  const Height(10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void closeDrawer(BuildContext context) {
    if (Scaffold.of(context).isDrawerOpen) {
      Scaffold.of(context).closeDrawer();
    }
  }
}
