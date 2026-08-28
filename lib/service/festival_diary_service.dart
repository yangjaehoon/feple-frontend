import 'dart:typed_data';
import 'package:feple/common/util/image_upload_helper.dart';
import 'package:feple/model/festival_diary_model.dart';
import 'package:feple/model/festival_diary_page.dart';
import 'package:feple/common/util/response_parsing.dart';
import 'package:feple/network/dio_client.dart';

class FestivalDiaryService {
  static const presignEndpoint = '/diaries/presign';

  /// 사진 여러 장 업로드 → 서버에 일기 작성
  Future<void> create({
    required int festivalId,
    required String content,
    required DiaryVisibility visibility,
    required List<Uint8List> images,
  }) async {
    final uploaded = await Future.wait(images.map(
      (bytes) => ImageUploadHelper.compressAndUpload(
        presignEndpoint: presignEndpoint,
        imageData: bytes,
      ),
    ));
    await DioClient.dio.post(
      '/diaries',
      data: {
        'festivalId': festivalId,
        'content': content,
        'visibility': visibility.value,
        'photoKeys': uploaded.map((p) => p.objectKey).toList(),
      },
    );
  }

  /// 내 일기 목록 조회 (festivalId 없으면 전체)
  Future<List<FestivalDiaryModel>> getMyDiaries({int? festivalId}) async {
    final response = await DioClient.dio.get(
      '/diaries/mine',
      queryParameters: festivalId != null ? {'festivalId': festivalId} : null,
    );
    return response.toModelList(FestivalDiaryModel.fromJson);
  }

  /// 일기 상세 조회
  Future<FestivalDiaryModel> getDiary(int diaryId) async {
    final response = await DioClient.dio.get('/diaries/$diaryId');
    return FestivalDiaryModel.fromJson(extractJsonMap(response.data));
  }

  /// 일기 내용/공개범위 수정
  Future<void> update(int diaryId, String content, DiaryVisibility visibility) async {
    await DioClient.dio.put(
      '/diaries/$diaryId',
      data: {'content': content, 'visibility': visibility.value},
    );
  }

  /// 일기 삭제 (command only — CQS)
  Future<void> delete(int diaryId) => DioClient.dio.delete('/diaries/$diaryId');

  /// 특정 유저가 쓴 공개 일기 목록 조회 (다른 유저 프로필용)
  Future<FestivalDiaryPage> getUserPublicDiaries(int userId, {int page = 0}) async {
    final response = await DioClient.dio.get(
      '/diaries/user/$userId/public',
      queryParameters: {'page': page},
    );
    return FestivalDiaryPage.fromJson(extractJsonMap(response.data));
  }
}
