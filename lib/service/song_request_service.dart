import 'package:feple/model/song_request_model.dart';
import 'package:feple/network/dio_client.dart';

class SongRequestService {
  Future<void> submit({
    required int artistId,
    required String songTitle,
    String? youtubeUrl,
  }) =>
      DioClient.dio.post(
        '/artists/$artistId/song-requests',
        data: {
          'songTitle': songTitle,
          if (youtubeUrl != null && youtubeUrl.isNotEmpty) 'youtubeUrl': youtubeUrl,
        },
      );

  Future<List<SongRequestModel>> fetchMyRequests(int artistId) async {
    final response =
        await DioClient.dio.get('/artists/$artistId/song-requests/my');
    return (response.data as List)
        .map((json) => SongRequestModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
