import 'package:feple/common/theme/color/abs_theme_colors.dart';
import 'package:feple/model/cert_state.dart';
import 'package:flutter/material.dart';

String? genreI18nKey(String genre) => switch (genre) {
      'BAND'    => 'genre_band',
      'HIP_HOP' => 'genre_hip_hop',
      'INDIE'   => 'genre_indie',
      'BALLAD'  => 'genre_ballad',
      'RNB'     => 'genre_rnb',
      'DANCE'   => 'genre_dance',
      'IDOL'    => 'genre_idol',
      'ETC'     => 'genre_etc',
      _         => null,
    };

String? ageI18nKey(String age) => switch (age) {
      'ALL_AGES' => 'age_all',
      'AGE_8'    => 'age_8',
      'AGE_12'   => 'age_12',
      'AGE_15'   => 'age_15',
      'AGE_19'   => 'age_19',
      _          => null,
    };

Color ageDisplayColor(String age) => switch (age) {
      'ALL_AGES' => AppColors.ageRatingBlue,
      'AGE_8'    => AppColors.ageRatingLightGreen,
      'AGE_12'   => AppColors.ageRatingGreen,
      'AGE_15'   => AppColors.ageRatingOrange,
      'AGE_19'   => AppColors.ageRatingRed,
      _          => Colors.white,
    };

extension CertStateStyle on CertState {
  IconData get icon => this == CertState.pending
      ? Icons.hourglass_top_rounded
      : Icons.verified_rounded;

  Color color(AbstractThemeColors colors) => switch (this) {
        CertState.certified => colors.activate.withValues(alpha: 0.7),
        CertState.pending   => AppColors.statusPending,
        CertState.none      => Colors.white,
      };

  Color? bgColor(AbstractThemeColors colors) => switch (this) {
        CertState.certified => colors.activate.withValues(alpha: 0.35),
        CertState.pending   => AppColors.statusPending.withValues(alpha: 0.25),
        CertState.none      => null,
      };
}
