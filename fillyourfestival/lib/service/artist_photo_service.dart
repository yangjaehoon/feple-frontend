import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:fast_app_base/network/dio_client.dart';

import 'package:fast_app_base/screen/main/tab/home/artist_page/img_collection/dto_presign_response.dart';

/// 아티스트 사진 업로드 서비스
class ArtistPhotoService {
  /// 이미지를 압축 → presign URL 요청 → S3 업로드 → 서버에 등록
  Future<void> uploadPhoto({
    required int artistId,
    required Uint8List imageData,
    required String title,
    required String description,
  }) async {
    // 1) 압축
    final compressed = await FlutterImageCompress.compressWithList(
        imageData, quality: 50);

    const contentType = 'image/jpeg';
    const ext = 'jpg';

    // 2) presigned URL 요청
    final presignRes = await DioClient.dio.post(
      '/artists/$artistId/photos/presign',
      data: {'contentType': contentType, 'extension': ext},
    );
    final presign = PresignResponse.fromJson(presignRes.data);

    // 3) S3 업로드 (외부 URL → http 유지)
    final putRes = await http.put(
      Uri.parse(presign.uploadUrl),
      headers: {'Content-Type': contentType},
      body: compressed,
    );
    if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
      throw Exception('S3 upload failed: ${putRes.statusCode}');
    }

    // 4) 서버에 등록
    await DioClient.dio.post(
      '/artists/$artistId/photos',
      data: {
        'objectKey': presign.objectKey,
        'contentType': contentType,
        'title': title,
        'description': description,
      },
    );
  }
}
