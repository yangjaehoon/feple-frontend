import 'dart:typed_data';
import 'package:feple/model/presign_response.dart';
import 'package:feple/network/dio_client.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

abstract final class ImageUploadHelper {
  static const int _compressQuality = 50;
  static const String _contentType = 'image/jpeg';
  static const String _ext = 'jpg';

  /// 이미지를 압축 → presigned URL 요청 → S3 업로드 순서로 처리.
  /// [presignEndpoint] 서버의 presign 발급 엔드포인트.
  /// 반환값으로 objectKey 등 이후 서버 등록에 필요한 [PresignResponse]를 제공.
  static Future<PresignResponse> compressAndUpload({
    required String presignEndpoint,
    required Uint8List imageData,
  }) async {
    final compressed = await FlutterImageCompress.compressWithList(
      imageData,
      quality: _compressQuality,
    );

    final presignResponse = await DioClient.dio.post(
      presignEndpoint,
      data: {'contentType': _contentType, 'extension': _ext},
    );
    final presign = PresignResponse.fromJson(presignResponse.data);

    final putResponse = await http.put(
      Uri.parse(presign.uploadUrl),
      headers: {'Content-Type': _contentType},
      body: compressed,
    );
    if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
      throw Exception('S3 upload failed: ${putResponse.statusCode}');
    }

    return presign;
  }
}
