import 'package:flutter/material.dart';

/// [keyword]와 일치하는 부분을 [highlightColor]로 강조한 TextSpan 리스트 반환.
/// [base]의 다른 스타일 속성은 유지됨.
List<TextSpan> buildHighlightSpans(
  String text,
  String keyword,
  TextStyle base,
  Color highlightColor,
) {
  if (keyword.isEmpty) return [TextSpan(text: text, style: base)];
  final pattern = RegExp(RegExp.escape(keyword), caseSensitive: false);
  final spans = <TextSpan>[];
  int last = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > last) {
      spans.add(TextSpan(text: text.substring(last, match.start), style: base));
    }
    spans.add(TextSpan(
      text: text.substring(match.start, match.end),
      style: base.copyWith(color: highlightColor, fontWeight: FontWeight.w700),
    ));
    last = match.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last), style: base));
  return spans;
}

/// [keyword]와 일치하는 부분을 강조한 Widget 반환.
/// keyword가 null이거나 비어 있으면 일반 Text 반환.
Widget buildHighlightedText(
  String text,
  String? keyword,
  TextStyle baseStyle,
  Color highlightColor, {
  int maxLines = 1,
}) {
  if (keyword == null || keyword.isEmpty) {
    return Text(text, style: baseStyle, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
  return RichText(
    text: TextSpan(
      style: baseStyle,
      children: buildHighlightSpans(text, keyword, baseStyle, highlightColor),
    ),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}
