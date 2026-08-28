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

    test('호스트 유사 문자열 우회는 false', () {
      expect(isValidYoutubeUrl('https://youtube.com.evil.com/watch'), isFalse);
      expect(isValidYoutubeUrl('https://evil.com/?x=youtube.com'), isFalse);
      expect(isValidYoutubeUrl('https://notyoutube.com/watch'), isFalse);
    });

    test('music.youtube.com / www.youtube.com 허용', () {
      expect(isValidYoutubeUrl('https://music.youtube.com/watch?v=a'), isTrue);
      expect(isValidYoutubeUrl('https://www.youtube.com/watch?v=a'), isTrue);
    });
  });

  group('isSafeExternalUrl', () {
    test('http(s) + 호스트 있으면 true', () {
      expect(isSafeExternalUrl('https://ticket.example.com/a'), isTrue);
      expect(isSafeExternalUrl('http://interpark.com'), isTrue);
    });

    test('위험 스킴 / 호스트 없음은 false', () {
      expect(isSafeExternalUrl('javascript:alert(1)'), isFalse);
      expect(isSafeExternalUrl('intent://scan/#Intent;scheme=x;end'), isFalse);
      expect(isSafeExternalUrl('tel:01012345678'), isFalse);
      expect(isSafeExternalUrl('file:///etc/passwd'), isFalse);
      expect(isSafeExternalUrl('https:///nohost'), isFalse);
      expect(isSafeExternalUrl(''), isFalse);
    });
  });
}
