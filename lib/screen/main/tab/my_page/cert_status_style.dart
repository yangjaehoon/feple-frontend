import 'package:feple/common/common.dart';
import 'package:feple/model/certification_model.dart';
import 'package:flutter/material.dart';

extension CertStatusStyle on CertStatus {
  String get labelKey => switch (this) {
    CertStatus.approved => 'cert_status_approved',
    CertStatus.pending  => 'cert_status_pending',
    CertStatus.rejected => 'cert_status_rejected',
  };

  Color displayColor(AbstractThemeColors colors) => switch (this) {
    CertStatus.approved => colors.certRingColor,
    CertStatus.pending  => AppColors.statusPending,
    CertStatus.rejected => colors.textSecondary,
  };
}
