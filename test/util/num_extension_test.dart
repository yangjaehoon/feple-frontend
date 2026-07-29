import 'package:feple/common/dart/extension/num_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IntDisplayExt.toDisplayCount (ko)', () {
    test('1000 미만은 그대로 표시한다', () {
      expect(999.toDisplayCount('ko'), '999');
    });

    test('1000 이상은 천 단위로 축약한다', () {
      expect(1500.toDisplayCount('ko'), '1.5천');
    });

    test('10000 이상은 만 단위로 축약한다', () {
      expect(15000.toDisplayCount('ko'), '1.5만');
    });
  });

  group('IntDisplayExt.toDisplayCount (en)', () {
    test('1000 미만은 그대로 표시한다', () {
      expect(999.toDisplayCount('en'), '999');
    });

    test('1000 이상은 K 단위로 축약한다', () {
      expect(1500.toDisplayCount('en'), '1.5K');
    });

    test('1000000 이상은 M 단위로 축약한다', () {
      expect(2500000.toDisplayCount('en'), '2.5M');
    });
  });
}
