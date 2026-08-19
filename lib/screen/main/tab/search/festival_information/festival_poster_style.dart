import 'package:feple/common/theme/color/abs_theme_colors.dart';
import 'package:feple/model/poster_cert_state.dart';
import 'package:flutter/material.dart';

export 'package:feple/model/festival_genre_style.dart';

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

extension CertStateStyle on PosterCertState {
  IconData get icon => this == PosterCertState.pending
      ? Icons.hourglass_top_rounded
      : Icons.verified_rounded;

  Color color(AbstractThemeColors colors) => switch (this) {
        PosterCertState.certified => colors.activate.withValues(alpha: 0.7),
        PosterCertState.pending   => AppColors.statusPending,
        PosterCertState.none      => Colors.white,
      };

  Color? bgColor(AbstractThemeColors colors) => switch (this) {
        PosterCertState.certified => colors.activate.withValues(alpha: 0.35),
        PosterCertState.pending   => AppColors.statusPending.withValues(alpha: 0.25),
        PosterCertState.none      => null,
      };
}
