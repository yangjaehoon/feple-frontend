import 'package:easy_localization/easy_localization.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/screen/main/tab/search/artist_genre_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Artist _artist({int id = 1, String genre = ''}) => Artist(
      id: id,
      name: '아티스트$id',
      genre: genre,
      profileImageUrl: '',
      followerCount: 0,
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('artistGenreLabel', () {
    test('매핑에 있는 장르는 i18n 라벨로 변환한다', () {
      expect(artistGenreLabel('Band'), 'genre_band'.tr());
      expect(artistGenreLabel('댄스'), 'genre_dance'.tr());
    });

    test('매핑에 없는 장르는 원문 그대로 반환한다', () {
      expect(artistGenreLabel('알 수 없는 장르'), '알 수 없는 장르');
    });
  });

  group('extractArtistGenres', () {
    test('아티스트 목록에서 중복 없는 장르를 정렬해 추출한다', () {
      final artists = [
        _artist(id: 1, genre: 'Band, Indie'),
        _artist(id: 2, genre: 'Indie'),
        _artist(id: 3, genre: 'Ballad'),
      ];

      expect(extractArtistGenres(artists), ['Ballad', 'Band', 'Indie']);
    });

    test('장르가 없으면 빈 목록을 반환한다', () {
      expect(extractArtistGenres([_artist()]), isEmpty);
    });
  });
}
