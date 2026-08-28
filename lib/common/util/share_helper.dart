import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/util/widget_image_capturer.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// 텍스트(+선택적으로 위젯 카드 이미지)를 OS 공유 시트로 내보낸다.
///
/// [cardToCapture] 가 주어지면 화면 밖에서 PNG로 캡처해 첨부한다. 캡처에 필요한
/// 네트워크 이미지는 [precacheImageUrl] 로 미리 로드한다. 캡처가 실패하면 텍스트만
/// 공유한다. 반환값은 공유 성공 여부 — false 면 호출부가 사용자에게 실패를 알린다
/// (사용자 노출 메시지는 호출부가 i18n 키로 처리).
Future<bool> shareContent(
  BuildContext context, {
  required String text,
  Widget? cardToCapture,
  String? precacheImageUrl,
  String captureFileName = 'feple_share.png',
  String logTag = 'Share',
}) async {
  List<XFile>? files;
  if (cardToCapture != null) {
    try {
      if (precacheImageUrl != null && precacheImageUrl.isNotEmpty) {
        await precacheImage(CachedNetworkImageProvider(precacheImageUrl), context);
      }
      if (!context.mounted) return false;
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
    await SharePlus.instance.share(ShareParams(text: text, files: files));
    return true;
  } catch (e) {
    debugPrint('[$logTag] share error: $e');
    return false;
  }
}
