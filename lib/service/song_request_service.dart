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

  Future<List<SongRequestModel>> fetchAllMyRequests(int userId) =>
      _fetchRequests('/users/$userId/song-requests');

  Future<List<SongRequestModel>> _fetchRequests(String endpoint) async {
    final response = await DioClient.dio.get(endpoint);
    return (response.data as List)
        .map((json) => SongRequestModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
