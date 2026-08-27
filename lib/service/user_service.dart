import 'package:dio/dio.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/util/response_parsing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/model/nickname_check_result.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/model/withdrawal_reason.dart';
import 'package:feple/network/dio_client.dart';

class UserService {
  Future<AppUser> fetchUser(int userId) async {
    final response = await DioClient.dio.get('/users/$userId');
    return AppUser.fromJson(extractJsonMap(response.data));
  }

  Future<AppUser> fetchUserFromToken(String token) async {
    final response = await DioClient.dio.get(
      '/users/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return AppUser.fromJson(extractJsonMap(response.data));
  }

  Future<void> deleteUser(int userId, WithdrawalReason reason, {String? detail}) async {
    await DioClient.dio.delete('/users/$userId', data: {
      'reason': reason.apiValue,
      if (detail != null && detail.isNotEmpty) 'detail': detail,
    });
  }

  Future<List<FollowedArtist>> fetchFollowingArtists(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/following');
    return response.toModelList(FollowedArtist.fromJson);
  }

  Future<List<FestivalModel>> fetchLikedFestivals(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/liked-festivals');
    return response.toModelList(FestivalModel.fromJson);
  }

  Future<void> updateProfileImage(int userId, XFile image) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path, filename: image.name),
    });
    await DioClient.dio.post('/users/$userId/profile-image', data: formData);
  }

  Future<void> updateNickname(int userId, String nickname) =>
      DioClient.dio.put('/users/$userId', data: {'nickname': nickname});

  Future<void> updateBio(int userId, String bio) => withBannedWordCheck(
        () => DioClient.dio.patch('/users/$userId/bio', data: {'bio': bio}),
        defaultField: 'bio',
      );

  Future<NicknameCheckResult> checkNicknameAvailability(
    String nickname, {
    int? excludeUserId,
  }) async {
    final response = await DioClient.dio.get(
      '/users/check-nickname',
      queryParameters: {
        'nickname': nickname,
        'excludeUserId': ?excludeUserId,
      },
    );
    return NicknameCheckResult.fromJson(response.data as Map<String, dynamic>);
  }
}
