import 'package:feple/model/artist_model.dart';
import 'package:feple/network/dio_client.dart';

class ArtistService {
  Future<List<Artist>> fetchArtists() async {
    final response = await DioClient.dio.get('/artists');
    final raw = response.data;
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => Artist.fromJson(e))
        .toList();
  }
}
