import 'package:feple/model/song_model.dart';
import 'package:feple/network/dio_client.dart';

class SongService {
  Future<List<SongModel>> fetchSongs(int artistId) async {
    final response = await DioClient.dio.get('/artists/$artistId/songs');
    return response.toModelList(SongModel.fromJson);
  }
}
