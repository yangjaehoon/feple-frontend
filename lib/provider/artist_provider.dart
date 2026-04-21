import 'package:feple/network/dio_client.dart';
import '../model/artist_model.dart';

Future<List<Artist>> fetchArtists() async {
  final res = await DioClient.dio.get('/artists');

  if (res.statusCode != 200) {
    throw Exception('Failed to load artists: ${res.statusCode}');
  }

  final raw = res.data;
  if (raw is! List) return [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map((e) => Artist.fromJson(e))
      .toList();
}