import 'dart:typed_data';

import 'package:feple/common/common.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';

/// 인증사진 업로드 → 실패 시 에러 스낵바까지 처리하고 성공 여부를 반환.
/// 성공 후 스낵바/화면 전환(즉시 pop vs 성공 애니메이션 후 pop 등)은
/// 호출부마다 달라 여기서 처리하지 않고 반환값으로 위임한다.
Future<bool> submitCertification(
  BuildContext context, {
  required CertificationService certService,
  required int festivalId,
  required Uint8List imageData,
}) async {
  try {
    await certService.submit(festivalId: festivalId, imageData: imageData);
    return true;
  } catch (e) {
    debugPrint('cert submit error: $e');
    if (context.mounted) {
      context.showErrorSnackbar(
        networkAwareErrorKey(
          e,
          isDioConflict(e) ? 'cert_already_submitted' : 'cert_submit_failed',
        ).tr(),
      );
    }
    return false;
  }
}
