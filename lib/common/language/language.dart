import 'package:flutter/material.dart';

import '../../app.dart';
import '../common.dart';

const _flagBasePath = 'assets/image';

enum Language {
  korean(Locale('ko'), '$_flagBasePath/flag/flag_kr.png'),
  english(Locale('en'), '$_flagBasePath/flag/flag_us.png');

  final Locale locale;
  final String flagPath;

  const Language(this.locale, this.flagPath);

  static Language find(String key) {
    return Language.values.asNameMap()[key] ?? Language.english;
  }
}

Language get currentLanguage {
  final ctx = App.navigatorKey.currentContext;
  if (ctx == null) return Language.korean;
  return ctx.isEnglish ? Language.english : Language.korean;
}
