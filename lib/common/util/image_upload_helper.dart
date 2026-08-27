import 'package:feple/model/presign_result.dart';
import 'package:feple/network/dio_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

abstract final class ImageUploadHelper {
  static const int _compressQuality = 50;
  static const String _contentType = 'image/jpeg';
  static const String _ext = 'jpg';

  /// 이미지를 압축 → presigned URL 요청 → S3 업로드 순서로 처리.
  /// [presignEndpoint] 서버의 presign 발급 엔드포인트.
  /// 반환값으로 objectKey 등 이후 서버 등록에 필요한 [PresignResult]를 제공.
  static Future<PresignResult> compressAndUpload({
    required String presignEndpoint,
    required Uint8List imageData,
  }) async {
    // 압축과 presign 요청은 서로 무관 — presign 요청 바디가 고정된
    // contentType/extension만 담아 압축 결과를 필요로 하지 않으므로 병렬 실행
    final (compressed, presignResponse) = await (
      FlutterImageCompress.compressWithList(
        imageData,
        quality: _compressQuality,
        format: CompressFormat.jpeg,
      ),
      DioClient.dio.post(
        presignEndpoint,
        data: {'contentType': _contentType, 'extension': _ext},
      ),
    ).wait;
    final presign = PresignResult.fromJson(presignResponse.data);

    final putResponse = await http.put(
      Uri.parse(presign.uploadUrl),
      headers: {'Content-Type': _contentType},
      body: compressed,
    );
    if (putResponse.statusCode < 200 || putResponse.statusCode >= 300) {
      debugPrint('[ImageUpload] S3 upload failed: ${putResponse.statusCode}');
      throw Exception('S3 upload failed');
    }

    return presign;
  }
}
