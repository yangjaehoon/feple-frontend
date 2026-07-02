import 'package:feple/network/dio_client.dart';

class ArtistSuggestionService {
  Future<void> submit({
    required String artistName,
    String? note,
  }) =>
      DioClient.dio.post(
        '/artist-suggestions',
        data: {
          'artistName': artistName,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
}
