import 'package:feple/model/localized_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pickLocalized', () {
    test('영어이고 en이 비어있지 않으면 en을 반환한다', () {
      expect(pickLocalized(true, '한글', 'English'), 'English');
    });

    test('영어이지만 en이 비어있으면 primary를 반환한다', () {
      expect(pickLocalized(true, '한글', ''), '한글');
    });

    test('영어가 아니면 primary를 반환한다', () {
      expect(pickLocalized(false, '한글', 'English'), '한글');
    });
  });
}
