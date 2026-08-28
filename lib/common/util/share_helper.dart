import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/util/widget_image_capturer.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// 공유 카드 배경 이미지를 미리 로드하는 최대 대기 시간. 초과하면 이미지 없이
/// 텍스트만 공유한다 (느린 네트워크에서 공유 시트가 안 뜨고 멈추는 것 방지).
const _precacheTimeout = Duration(seconds: 4);

/// 텍스트(+선택적으로 위젯 카드 이미지)를 OS 공유 시트로 내보낸다.
///
/// [cardToCapture] 가 주어지면 화면 밖에서 PNG로 캡처해 첨부한다. 캡처에 필요한
/// 네트워크 이미지는 [precacheImageUrl] 로 미리 로드하며, 로드가 [_precacheTimeout]
/// 을 넘기거나 실패하면 캡처를 건너뛰고 텍스트만 공유한다. 반환값은 공유 성공
/// 여부 — false 면 호출부가 사용자에게 실패를 알린다(메시지는 호출부가 i18n 키로).
Future<bool> shareContent(
  BuildContext context, {
  required String text,
  Widget? cardToCapture,
  String? precacheImageUrl,
  String captureFileName = 'feple_share.png',
  String logTag = 'Share',
  @visibleForTesting Future<void> Function(ShareParams params)? shareOverride,
}) async {
  List<XFile>? files;
  if (cardToCapture != null &&
      await _precacheReady(context, precacheImageUrl, logTag)) {
    if (!context.mounted) return false;
    try {
      final bytes = await captureWidgetAsPng(context, cardToCapture);
      if (bytes != null) {
        files = [
          XFile.fromData(bytes, name: captureFileName, mimeType: 'image/png'),
        ];
      }
    } catch (e) {
      debugPrint('[$logTag] card capture failed: $e');
    }
  }
  try {
    final share = shareOverride ?? (p) => SharePlus.instance.share(p);
    await share(ShareParams(text: text, files: files));
    return true;
  } catch (e) {
    debugPrint('[$logTag] share error: $e');
    return false;
  }
}

/// 배경 이미지를 제한 시간 안에 로드한다. URL이 없으면 그대로 진행(true),
/// 로드 실패/타임아웃이면 이미지 없이 공유하도록 false.
Future<bool> _precacheReady(
  BuildContext context,
  String? url,
  String logTag,
) async {
  if (url == null || url.isEmpty) return true;
  try {
    await precacheImage(CachedNetworkImageProvider(url), context)
        .timeout(_precacheTimeout);
    return true;
  } catch (e) {
    debugPrint('[$logTag] precache failed/timed out: $e');
    return false;
  }
}
