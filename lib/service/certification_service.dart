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
}
