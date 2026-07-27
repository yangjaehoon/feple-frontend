import 'package:feple/common/theme/color/abs_theme_colors.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/model/poster_cert_state.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_poster_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AbstractThemeColors colors = CustomTheme.light.appColors;

  group('genreI18nKey', () {
    test('알려진 장르는 i18n 키를 반환한다', () {
      expect(genreI18nKey('BAND'), 'genre_band');
      expect(genreI18nKey('HIP_HOP'), 'genre_hip_hop');
      expect(genreI18nKey('IDOL'), 'genre_idol');
    });

    test('알 수 없는 장르는 null을 반환한다', () {
      expect(genreI18nKey('UNKNOWN'), isNull);
    });
  });

  group('ageI18nKey', () {
    test('알려진 연령 등급은 i18n 키를 반환한다', () {
      expect(ageI18nKey('ALL_AGES'), 'age_all');
      expect(ageI18nKey('AGE_19'), 'age_19');
    });

    test('알 수 없는 값은 null을 반환한다', () {
      expect(ageI18nKey('UNKNOWN'), isNull);
    });
  });

  group('ageDisplayColor', () {
    test('알려진 연령 등급마다 다른 색상을 반환한다', () {
      expect(ageDisplayColor('ALL_AGES'), AppColors.ageRatingBlue);
      expect(ageDisplayColor('AGE_19'), AppColors.ageRatingRed);
    });

    test('알 수 없는 값은 흰색을 반환한다', () {
      expect(ageDisplayColor('UNKNOWN'), Colors.white);
    });
  });

  group('CertStateStyle', () {
    test('pending은 모래시계 아이콘, 그 외는 인증 아이콘', () {
      expect(PosterCertState.pending.icon, Icons.hourglass_top_rounded);
      expect(PosterCertState.certified.icon, Icons.verified_rounded);
      expect(PosterCertState.none.icon, Icons.verified_rounded);
    });

    test('none 상태는 bgColor가 null', () {
      expect(PosterCertState.none.bgColor(colors), isNull);
    });

    test('certified/pending 상태는 bgColor가 있다', () {
      expect(PosterCertState.certified.bgColor(colors), isNotNull);
      expect(PosterCertState.pending.bgColor(colors), isNotNull);
    });
  });
}
