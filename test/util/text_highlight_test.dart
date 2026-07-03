import 'package:feple/common/util/text_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = TextStyle(fontSize: 14, color: Colors.black);
  const highlight = Colors.blue;

  group('buildHighlightSpans', () {
    test('keyword가 빈 문자열이면 전체 텍스트를 단일 span으로 반환', () {
      final spans = buildHighlightSpans('Hello World', '', base, highlight);
      expect(spans.length, 1);
      expect(spans.first.text, 'Hello World');
      expect(spans.first.style, base);
    });

    test('매칭 없으면 전체 텍스트를 단일 span으로 반환', () {
      final spans = buildHighlightSpans('Hello World', 'xyz', base, highlight);
      expect(spans.length, 1);
      expect(spans.first.text, 'Hello World');
    });

    test('전체 텍스트가 keyword와 일치하면 강조 span 하나만 반환', () {
      final spans = buildHighlightSpans('hello', 'hello', base, highlight);
      expect(spans.length, 1);
      expect(spans.first.text, 'hello');
      expect(spans.first.style?.color, highlight);
      expect(spans.first.style?.fontWeight, FontWeight.w700);
    });

    test('중간에 keyword가 있으면 앞·강조·뒤 3개 span 반환', () {
      final spans = buildHighlightSpans('say hello world', 'hello', base, highlight);
      expect(spans.length, 3);
      expect(spans[0].text, 'say ');
      expect(spans[1].text, 'hello');
      expect(spans[1].style?.color, highlight);
      expect(spans[2].text, ' world');
    });

    test('keyword가 대소문자 구분 없이 매칭됨', () {
      final spans = buildHighlightSpans('say HELLO world', 'hello', base, highlight);
      expect(spans.length, 3);
      expect(spans[1].text, 'HELLO');
      expect(spans[1].style?.color, highlight);
    });

    test('여러 번 매칭되면 그 수만큼 강조 span이 생성됨', () {
      final spans = buildHighlightSpans('a b a', 'a', base, highlight);
      // 'a'(강조), ' b '(일반), 'a'(강조) → 총 3개
      expect(spans.length, 3);
      expect(spans[0].style?.color, highlight);
      expect(spans[1].style?.color, isNot(highlight));
      expect(spans[2].style?.color, highlight);
    });

    test('정규식 특수문자가 keyword에 포함돼도 안전하게 처리됨', () {
      // RegExp.escape로 처리되므로 예외 없이 동작해야 함
      final spans = buildHighlightSpans('a(b)c', '(b)', base, highlight);
      expect(spans.any((s) => s.text == '(b)' && s.style?.color == highlight), true);
    });

    test('매칭된 span은 base 스타일에서 color·fontWeight만 변경됨', () {
      final spans = buildHighlightSpans('hello', 'hello', base, highlight);
      final span = spans.first;
      expect(span.style?.fontSize, base.fontSize);
    });
  });
}
