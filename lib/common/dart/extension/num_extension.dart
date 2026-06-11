import 'package:easy_localization/easy_localization.dart';

final decimalFormat = NumberFormat.decimalPattern("en");

extension IntExt on int {
  static int? safeParse(String? source) {
    if (source == null) return null;
    return int.tryParse(source);
  }

  String toComma() {
    return decimalFormat.format(this);
  }

  String get withPlusMinus {
    if (this > 0) {
      return "+$this";
    } else if (this < 0) {
      return "$this";
    } else {
      return "0";
    }
  }
}

extension DoubleExt on double {
  String toComma() {
    return decimalFormat.format(this);
  }
}

extension IntDisplayExt on int {
  /// 팔로워 수 등 큰 숫자를 언어에 맞게 축약 표시 (1500 → ko: 1.5천 / en: 1.5K)
  String toDisplayCount(String lang) {
    if (lang == 'en') {
      if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
      if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}K';
      return toString();
    }
    if (this >= 10000) return '${(this / 10000).toStringAsFixed(1)}만';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}천';
    return toString();
  }
}
