import 'package:feple/model/festival_preview.dart';
import 'package:feple/network/dio_client.dart';

/// 아티스트 일정(페스티벌) 조회 서비스.
/// w_edit_photo_sheet, w_img_upload 등에서 공통으로 사용합니다.
class ArtistScheduleService {
  static Future<List<FestivalPreview>> fetchFestivals(int artistId) async {
    final resp = await DioClient.dio.get('/artists/$artistId/schedule');
    final list = resp.data as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return FestivalPreview(
        id: (m['festivalId'] as num).toInt(),
        title: (m['title'] ?? '') as String,
        location: (m['location'] ?? '') as String,
        posterUrl: (m['posterUrl'] ?? '') as String,
        startDate: m['startDate']?.toString() ?? '',
      );
    }).toList();
  }
}
