import 'package:feple/model/artist_model.dart';
import 'package:feple/network/dio_client.dart';

class ArtistService {
  Future<Artist> fetchArtistById(int artistId) async {
    final response = await DioClient.dio.get('/artists/$artistId');
    return Artist.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Artist>> fetchArtists() async {
    final response = await DioClient.dio.get('/artists');
    return _parseArtistList(response.data);
  }

  Future<List<Artist>> fetchRelatedArtists(int artistId) async {
    final response = await DioClient.dio.get('/artists/$artistId/related');
    return _parseArtistList(response.data);
  }

  List<Artist> _parseArtistList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => Artist.fromJson(e))
        .toList();
  }
}
