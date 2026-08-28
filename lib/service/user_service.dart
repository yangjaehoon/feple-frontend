import 'package:dio/dio.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/util/image_upload_helper.dart';
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
    // 원본(최대 12MP)을 그대로 멀티파트로 올리면 현장 저신호에서 자주 실패 →
    // JPEG로 압축 후 전송. 경로 기반 압축이라 원본을 힙에 통째로 올리지 않음
    final compressed = await ImageUploadHelper.compressFileToJpeg(image.path);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        compressed,
        filename: 'profile.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
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
