import 'package:feple/model/song_model.dart';
import 'package:feple/network/dio_client.dart';

class SongService {
  Future<List<SongModel>> fetchSongs(int artistId) async {
    final response = await DioClient.dio.get('/artists/$artistId/songs');
    final songs = (response.data as List)
        .map((json) => SongModel.fromJson(json as Map<String, dynamic>))
        .toList();
    songs.sort((a, b) {
      final c = b.festivalCount.compareTo(a.festivalCount);
      return c != 0 ? c : a.title.compareTo(b.title);
    });
    return songs;
  }
}
