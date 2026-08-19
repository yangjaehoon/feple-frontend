/// 페스티벌 장르 코드(백엔드 enum 문자열)를 i18n 키로 변환. 매핑에 없는 코드는 null.
String? genreI18nKey(String genre) => switch (genre) {
      'BAND'    => 'genre_band',
      'HIP_HOP' => 'genre_hip_hop',
      'INDIE'   => 'genre_indie',
      'BALLAD'  => 'genre_ballad',
      'RNB'     => 'genre_rnb',
      'DANCE'   => 'genre_dance',
      'IDOL'    => 'genre_idol',
      'GUGAK'   => 'genre_gugak',
      'ETC'     => 'genre_etc',
      _         => null,
    };
