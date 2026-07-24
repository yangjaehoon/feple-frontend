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
