import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:feple/network/dio_client.dart';
import 'package:feple/model/presign_response.dart';

class CertificationService {
  /// 인증 사진 업로드 → 서버에 인증 신청
  Future<Map<String, dynamic>> submit({
    required int festivalId,
    required Uint8List imageData,
  }) async {
    // 1) 압축
    final compressed = await FlutterImageCompress.compressWithList(
        imageData, quality: 50);

    const contentType = 'image/jpeg';
    const ext = 'jpg';

    // 2) presigned URL 요청
    final presignRes = await DioClient.dio.post(
      '/certifications/presign',
      data: {'contentType': contentType, 'extension': ext},
    );
    final presign = PresignResponse.fromJson(presignRes.data);

    // 3) S3 업로드
    final putRes = await http.put(
      Uri.parse(presign.uploadUrl),
      headers: {'Content-Type': contentType},
      body: compressed,
    );
    if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
      throw Exception('S3 upload failed: ${putRes.statusCode}');
    }

    // 4) 서버에 인증 신청
    final submitRes = await DioClient.dio.post(
      '/certifications',
      data: {
        'festivalId': festivalId,
        'photoKey': presign.objectKey,
      },
    );
    return submitRes.data as Map<String, dynamic>;
  }

  /// 내 인증 목록 조회
  Future<List<Map<String, dynamic>>> getMyCertifications() async {
    final res = await DioClient.dio.get('/certifications/my');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  /// 승인된 페스티벌 ID 목록 조회
  Future<List<int>> getApprovedFestivalIds() async {
    final res = await DioClient.dio.get('/certifications/my/approved-festivals');
    return (res.data as List).cast<int>();
  }
}
