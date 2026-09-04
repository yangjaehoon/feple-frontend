import 'package:feple/common/common.dart';
import 'package:feple/common/util/url_validator.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// 외부 URL을 기본 브라우저/앱으로 연다.
///
/// - 위험 스킴(javascript:, file: 등)은 [isSafeExternalUrl]로 먼저 차단한다.
/// - `launchUrl`이 `false`를 반환하거나 예외(PlatformException 등)를 던지면
///   `link_open_failed` 스낵바를 띄운다.
///
/// 문의·약관·개인정보처리방침 등 외부 링크를 여는 모든 지점에서 이 헬퍼를 쓴다.
Future<void> openExternalUrl(BuildContext context, String url) async {
  if (!isSafeExternalUrl(url)) return;
  try {
    final launched =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      context.showErrorSnackbar('link_open_failed'.tr());
    }
  } catch (e) {
    debugPrint('[ExternalLink] $e');
    if (context.mounted) context.showErrorSnackbar('link_open_failed'.tr());
  }
}
