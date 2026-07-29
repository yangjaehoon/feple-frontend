import 'package:feple/model/genre_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('splitGenres', () {
    test('콤마+공백으로 구분된 장르 문자열을 리스트로 분해한다', () {
      expect(splitGenres('Band, Indie'), ['Band', 'Indie']);
    });

    test('null이면 빈 리스트를 반환한다', () {
      expect(splitGenres(null), <String>[]);
    });

    test('빈 문자열이면 빈 리스트를 반환한다', () {
      expect(splitGenres(''), <String>[]);
    });

    test('단일 장르는 리스트 하나로 반환한다', () {
      expect(splitGenres('Band'), ['Band']);
    });
  });
}
