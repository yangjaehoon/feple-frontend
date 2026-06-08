import 'package:feple/common/common.dart';
import 'package:feple/model/song_request_model.dart';
import 'package:flutter/material.dart';

extension SongRequestStatusStyle on SongRequestStatus {
  String get labelKey => switch (this) {
    SongRequestStatus.pending  => 'song_status_pending',
    SongRequestStatus.approved => 'song_status_approved',
    SongRequestStatus.rejected => 'song_status_rejected',
  };

  Color displayColor(AbstractThemeColors colors) => switch (this) {
    SongRequestStatus.pending  => colors.textSecondary,
    SongRequestStatus.approved => colors.activate,
    SongRequestStatus.rejected => AppColors.errorRed,
  };
}
