import 'package:feple/common/common.dart';
import 'package:feple/common/language/language.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/string_extensions.dart';
import 'package:simple_shadow/simple_shadow.dart';

class MenuLanguageSelector extends StatelessWidget {
  const MenuLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
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
              boxShadow: [context.appShadows.buttonShadowSmall],
            ),
            child: Row(
              children: [
                const Width(10),
                DropdownButton<String>(
                  items: [
                    _menuItem(context, currentLanguage),
                    _menuItem(
                      context,
                      Language.values
                          .where((e) => e != currentLanguage)
                          .first,
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    await context
                        .setLocale(Language.find(value.toLowerCase()).locale);
                  },
                  value: currentLanguage.name.capitalizeFirst,
                  underline: const SizedBox.shrink(),
                  elevation: 1,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          ),
          onTap: () async {},
        ),
      ],
    );
  }

  DropdownMenuItem<String> _menuItem(BuildContext context, Language language) {
    final colors = context.appColors;
    return DropdownMenuItem(
      value: language.name.capitalizeFirst,
      child: Row(
        children: [
          _flag(language.flagPath),
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

  Widget _flag(String path) {
    return SimpleShadow(
      opacity: 0.5,
      color: Colors.black45,
      offset: const Offset(2, 2),
      sigma: 2,
      child: Image.asset(path, width: 20),
    );
  }
}
