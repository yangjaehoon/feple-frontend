import 'package:feple/common/util/response_parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractJsonList', () {
    test('순수 배열은 그대로', () {
      expect(extractJsonList([1, 2, 3]), [1, 2, 3]);
    });

    test('Spring Page(content)에서 리스트 추출', () {
      expect(
        extractJsonList({'content': [1, 2], 'totalElements': 2}),
        [1, 2],
      );
    });

    test('data/items 래핑도 지원', () {
      expect(extractJsonList({'data': ['a']}), ['a']);
      expect(extractJsonList({'items': ['b']}), ['b']);
    });

    test('예상 밖 형태는 빈 리스트 (크래시 대신)', () {
      expect(extractJsonList({'error': 'boom'}), isEmpty);
      expect(extractJsonList(42), isEmpty);
      expect(extractJsonList(null), isEmpty);
    });

    test('문자열로 온 JSON 배열도 디코드', () {
      expect(extractJsonList('[1,2]'), [1, 2]);
    });
  });

  group('extractJsonMap', () {
    test('Map은 그대로', () {
      expect(extractJsonMap({'id': 1}), {'id': 1});
    });

    test('문자열 JSON은 디코드', () {
      expect(extractJsonMap('{"id":1}'), {'id': 1});
    });

    test('Map이 아니면 FormatException', () {
      expect(() => extractJsonMap('"just a string"'),
          throwsA(isA<FormatException>()));
      expect(() => extractJsonMap([1, 2]), throwsA(isA<FormatException>()));
    });
  });
}
