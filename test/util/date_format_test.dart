import 'package:feple/model/date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatShortDate', () {
    test('ISO 8601 문자열을 yyyy.MM.dd 형식으로 변환한다', () {
      expect(formatShortDate('2026-08-01T12:00:00Z'), '2026.08.01');
    });

    test('null이면 null을 반환한다', () {
      expect(formatShortDate(null), isNull);
    });

    test('파싱에 실패하면 원본 문자열을 반환한다', () {
      expect(formatShortDate('not-a-date'), 'not-a-date');
    });

    test('월/일이 한 자리면 0으로 패딩한다', () {
      expect(formatShortDate('2026-01-05T00:00:00Z'), '2026.01.05');
    });
  });
}
