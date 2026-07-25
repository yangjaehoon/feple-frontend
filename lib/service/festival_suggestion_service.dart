import 'package:feple/network/dio_client.dart';

class FestivalSuggestionService {
  Future<void> submit({
    required String festivalName,
    String? note,
  }) =>
      DioClient.dio.post(
        '/festival-suggestions',
        data: {
          'festivalName': festivalName,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
}
