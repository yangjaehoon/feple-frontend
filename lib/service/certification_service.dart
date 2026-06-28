import 'dart:typed_data';
import 'package:feple/common/util/image_upload_helper.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/network/dio_client.dart';

class CertificationService {
  /// 인증 사진 업로드 → 서버에 인증 신청
  Future<void> submit({
    required int festivalId,
    required Uint8List imageData,
  }) async {
    final presign = await ImageUploadHelper.compressAndUpload(
      presignEndpoint: '/certifications/presign',
      imageData: imageData,
    );
    await DioClient.dio.post(
      '/certifications',
      data: {
        'festivalId': festivalId,
        'photoKey': presign.objectKey,
      },
    );
  }

  /// 내 인증 목록 조회
  Future<List<CertificationModel>> getMyCertifications() async {
    final response = await DioClient.dio.get('/certifications');
    return (response.data as List)
        .cast<Map<String, dynamic>>()
        .map(CertificationModel.fromJson)
        .toList();
  }

  /// 승인된 페스티벌 ID 목록 조회
  Future<List<int>> getApprovedFestivalIds() async {
    final response = await DioClient.dio.get('/certifications/approved-festivals');
    return (response.data as List).cast<int>();
  }

  /// 특정 페스티벌의 인증 상태 단건 조회 (NONE / PENDING / APPROVED / REJECTED)
  Future<CertStatus?> getCertState(int festivalId) async {
    final response = await DioClient.dio.get(
      '/certifications/cert-state',
      queryParameters: {'festivalId': festivalId},
    );
    final state = (response.data as Map<String, dynamic>)['certState'] as String?;
    if (state == null || state == 'NONE') return null;
    return CertStatus.fromValue(state);
  }

  /// 인증된 페스티벌에 별점 및 한줄 후기 제출
  Future<void> submitRating(int certId, int rating, String? review) async {
    await DioClient.dio.put(
      '/certifications/$certId/rating',
      data: {'rating': rating, 'review': review},
    );
  }

  /// 페스티벌의 평균 별점 및 평가 수 조회
  Future<({double averageRating, int ratingCount})> getFestivalRating(int festivalId) async {
    final response = await DioClient.dio.get('/certifications/festival/$festivalId/rating');
    final data = response.data as Map<String, dynamic>;
    return (
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
