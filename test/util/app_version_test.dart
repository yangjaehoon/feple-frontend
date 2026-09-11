import 'package:feple/common/util/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseVersion', () {
    test('점 구분 숫자를 세그먼트 리스트로 파싱한다', () {
      expect(parseVersion('1.2.3'), [1, 2, 3]);
      expect(parseVersion('10.0'), [10, 0]);
      expect(parseVersion(' 2.5.1 '), [2, 5, 1]);
    });

    test('빌드/프리릴리스 메타데이터는 무시한다', () {
      expect(parseVersion('1.2.3+72'), [1, 2, 3]);
      expect(parseVersion('1.2.3-beta.1'), [1, 2, 3]);
    });

    test('숫자가 아니거나 비어 있으면 null', () {
      expect(parseVersion(null), isNull);
      expect(parseVersion(''), isNull);
      expect(parseVersion('abc'), isNull);
      expect(parseVersion('1.x.0'), isNull);
    });
  });

  group('isVersionBelow', () {
    test('current가 minimum보다 낮을 때만 true', () {
      expect(isVersionBelow('1.0.0', '1.2.0'), isTrue);
      expect(isVersionBelow('1.2.0', '1.10.0'), isTrue);
      expect(isVersionBelow('1.2.0', '1.2.0'), isFalse);
      expect(isVersionBelow('1.3.0', '1.2.0'), isFalse);
      expect(isVersionBelow('2.0.0', '1.9.9'), isFalse);
    });

    test('길이가 다르면 없는 세그먼트를 0으로 본다', () {
      expect(isVersionBelow('1.2', '1.2.0'), isFalse);
      expect(isVersionBelow('1.2', '1.2.1'), isTrue);
    });

    test('형식이 잘못되면 fail-open으로 false', () {
      expect(isVersionBelow('garbage', '1.2.0'), isFalse);
      expect(isVersionBelow('1.0.0', ''), isFalse);
    });
  });
}
