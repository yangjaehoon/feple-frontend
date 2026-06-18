import 'package:feple/model/notification_preference_model.dart';
import 'package:feple/network/dio_client.dart';

class NotificationPreferenceService {
  Future<NotificationPreferenceModel> getPreferences() async {
    final response = await DioClient.dio.get('/users/me/notification-preferences');
    return NotificationPreferenceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updatePreferences(NotificationPreferenceModel prefs) =>
      DioClient.dio.put(
        '/users/me/notification-preferences',
        data: {
          'certEnabled': prefs.certEnabled,
          'commentEnabled': prefs.commentEnabled,
          'festivalEnabled': prefs.festivalEnabled,
          'songRequestEnabled': prefs.songRequestEnabled,
        },
      );
}
