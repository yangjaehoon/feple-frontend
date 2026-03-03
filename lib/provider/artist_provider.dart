import 'package:fast_app_base/network/dio_client.dart';
import '../model/artist_model.dart';

Future<List<Artist>> fetchArtists() async {
  final res = await DioClient.dio.get('/artists');

  if (res.statusCode != 200) {
    throw Exception('Failed to load artists: ${res.statusCode}');
  }

  final data = res.data as List;
  return data
      .map((e) => Artist.fromJson(e as Map<String, dynamic>))
      .toList();
}