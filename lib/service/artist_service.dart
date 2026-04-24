import 'package:feple/model/artist_model.dart';
import 'package:feple/network/dio_client.dart';

class ArtistService {
  Future<List<Artist>> fetchArtists() async {
    final res = await DioClient.dio.get('/artists');
    if (res.statusCode != 200) {
      throw Exception('아티스트 로딩 실패: ${res.statusCode}');
    }
    final raw = res.data;
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => Artist.fromJson(e))
        .toList();
  }
}
