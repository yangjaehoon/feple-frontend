import 'package:feple/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

String? genreI18nKey(String genre) => switch (genre) {
      'HIP_HOP' => 'genre_hip_hop',
      'INDIE'   => 'genre_indie',
      'BAND'    => 'genre_band',
      'ETC'     => 'genre_etc',
      _         => null,
    };

String? ageI18nKey(String age) => switch (age) {
      'AGE_12' => 'age_12',
      'AGE_15' => 'age_15',
      'AGE_19' => 'age_19',
      _        => null,
    };

Color ageDisplayColor(String age) => switch (age) {
      'AGE_12' => AppColors.ageRatingGreen,
      'AGE_15' => AppColors.ageRatingOrange,
      'AGE_19' => AppColors.ageRatingRed,
      _        => Colors.white,
    };
