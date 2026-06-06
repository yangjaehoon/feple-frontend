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
    final response = await DioClient.dio.get('/certifications/my');
    return (response.data as List)
        .cast<Map<String, dynamic>>()
        .map(CertificationModel.fromJson)
        .toList();
  }

  /// 승인된 페스티벌 ID 목록 조회
  Future<List<int>> getApprovedFestivalIds() async {
    final response = await DioClient.dio.get('/certifications/my/approved-festivals');
    return (response.data as List).cast<int>();
  }

  /// 특정 페스티벌의 인증 상태 단건 조회 (NONE / PENDING / APPROVED / REJECTED)
  Future<CertStatus?> getCertState(int festivalId) async {
    final response = await DioClient.dio.get(
      '/certifications/my/cert-state',
      queryParameters: {'festivalId': festivalId},
    );
    final state = (response.data as Map<String, dynamic>)['certState'] as String?;
    if (state == null || state == 'NONE') return null;
    return CertStatus.fromValue(state);
  }
}
