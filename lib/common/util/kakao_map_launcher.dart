import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 좌표가 있으면 카카오맵 앱(`kakaomap://`)으로, 앱 실행이 안 되거나 좌표가
/// 없으면 카카오맵 웹으로 위치를 연다. 열기에 실패하면 스낵바로 알린다.
///
/// (예전엔 이 URL 스킴 조립 + 폴백 로직이 FestivalPoster 위젯 State 안에 있었음)
Future<void> openKakaoMap(
  BuildContext context, {
  double? latitude,
  double? longitude,
  required String locationName,
}) async {
  final name = Uri.encodeComponent(locationName);
  try {
    final launched = (latitude != null && longitude != null)
        ? await _launchByCoordinates(name, latitude, longitude)
        : await launchUrl(
            Uri.parse('https://map.kakao.com/link/search/$name'),
            mode: LaunchMode.externalApplication,
          );
    if (!launched && context.mounted) {
      context.showErrorSnackbar('map_open_failed'.tr());
    }
  } catch (e) {
    debugPrint('map launch error: $e');
    if (context.mounted) context.showErrorSnackbar('map_open_failed'.tr());
  }
}

Future<bool> _launchByCoordinates(String name, double lat, double lng) async {
  final appUri = Uri.parse('kakaomap://look?p=$lat,$lng');
  if (await canLaunchUrl(appUri) && await launchUrl(appUri)) return true;
  return launchUrl(
    Uri.parse('https://map.kakao.com/link/map/$name,$lat,$lng'),
    mode: LaunchMode.externalApplication,
  );
}
