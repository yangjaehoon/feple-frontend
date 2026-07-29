import 'package:feple/common/util/url_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidYoutubeUrl', () {
    test('https youtube.com URL은 true', () {
      expect(isValidYoutubeUrl('https://youtube.com/watch?v=abc'), isTrue);
    });

    test('http youtu.be URL은 true', () {
      expect(isValidYoutubeUrl('http://youtu.be/abc'), isTrue);
    });

    test('http(s) 스킴이 아니면 false', () {
      expect(isValidYoutubeUrl('ftp://youtube.com/watch?v=abc'), isFalse);
    });

    test('youtube 도메인이 아니면 false', () {
      expect(isValidYoutubeUrl('https://example.com'), isFalse);
    });

    test('javascript 스킴은 false', () {
      expect(isValidYoutubeUrl('javascript:alert(1)'), isFalse);
    });
  });
}
