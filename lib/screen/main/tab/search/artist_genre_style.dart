import 'package:feple/common/common.dart';
import 'package:feple/model/artist_model.dart';

/// 아티스트 장르 원문(예: 'Hip-hop', '댄스')을 i18n 라벨로 변환.
/// 매핑에 없는 장르는 원문 그대로 표시.
String artistGenreLabel(String genre) => switch (genre) {
  'Band'    => 'genre_band'.tr(),
  'Hip-hop' => 'genre_hip_hop'.tr(),
  'Indie'   => 'genre_indie'.tr(),
  'Ballad'  => 'genre_ballad'.tr(),
  'R&B'     => 'genre_rnb'.tr(),
  '댄스'     => 'genre_dance'.tr(),
  '아이돌'   => 'genre_idol'.tr(),
  _         => genre,
};

/// 아티스트 목록에서 중복 없는 장르 목록을 정렬해 추출.
List<String> extractArtistGenres(List<Artist> artists) =>
    artists.expand((a) => a.genres).toSet().toList()..sort();
