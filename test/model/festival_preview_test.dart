import 'package:feple/model/festival_preview.dart';
import 'package:flutter_test/flutter_test.dart';

FestivalPreview _preview({String? endDate}) => FestivalPreview(
      id: 1,
      title: '록페스티벌',
      location: '서울',
      posterUrl: 'https://example.com/poster.jpg',
      startDate: '2025-08-01',
      endDate: endDate,
    );

void main() {
  group('FestivalPreview.isEnded', () {
    test('endDate null이면 false', () {
      expect(_preview(endDate: null).isEnded, false);
    });

    test('endDate 빈 문자열이면 false', () {
      expect(_preview(endDate: '').isEnded, false);
    });

    test('과거 날짜이면 true', () {
      expect(_preview(endDate: '2000-01-01').isEnded, true);
    });

    test('미래 날짜이면 false', () {
      expect(_preview(endDate: '2099-12-31').isEnded, false);
    });

    test('잘못된 날짜 형식이면 false', () {
      expect(_preview(endDate: 'not-a-date').isEnded, false);
    });
  });

  group('FestivalPreview.fromJson', () {
    test('정상 필드 파싱', () {
      final json = {
        'id': 1,
        'title': '록페스티벌',
        'description': '설명',
        'location': '서울',
        'posterUrl': 'https://example.com/poster.jpg',
        'startDate': '2025-08-01',
        'endDate': '2025-08-03',
        'genres': ['Rock', 'Indie'],
        'region': '서울',
        'latitude': 37.5,
        'longitude': 127.0,
      };

      final preview = FestivalPreview.fromJson(json);

      expect(preview.id, 1);
      expect(preview.title, '록페스티벌');
      expect(preview.genres, ['Rock', 'Indie']);
      expect(preview.latitude, 37.5);
      expect(preview.endDate, '2025-08-03');
    });

    test('null 필드 기본값 적용', () {
      final json = {
        'id': 1,
        'title': null,
        'description': null,
        'location': null,
        'posterUrl': null,
        'startDate': null,
        'genres': null,
        'region': null,
        'latitude': null,
        'longitude': null,
      };

      final preview = FestivalPreview.fromJson(json);

      expect(preview.title, '');
      expect(preview.description, '');
      expect(preview.genres, isEmpty);
      expect(preview.latitude, isNull);
      expect(preview.region, isNull);
    });
  });
}
