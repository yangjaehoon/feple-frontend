import 'package:feple/model/presign_result.dart';
import 'package:feple/network/dio_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

abstract final class ImageUploadHelper {
  static const int _compressQuality = 50;
  static const String _contentType = 'image/jpeg';
  static const String _ext = 'jpg';

  /// 원본 이미지 바이트를 JPEG로 압축한다 (presign/S3 흐름 — 이미 메모리에
  /// 바이트가 있는 image_picker 결과용).
  static Future<Uint8List> compressToJpeg(Uint8List imageData) =>
      FlutterImageCompress.compressWithList(
        imageData,
        quality: _compressQuality,
        format: CompressFormat.jpeg,
      );

  /// 파일 경로를 직접 받아 JPEG로 압축한다. `readAsBytes()`로 원본(최대 12MP,
  /// 디코드 시 수십 MB)을 Dart 힙에 통째로 올리지 않아 저사양 기기 메모리에 유리.
  static Future<Uint8List> compressFileToJpeg(String path) async {
    final out = await FlutterImageCompress.compressWithFile(
      path,
      quality: _compressQuality,
      format: CompressFormat.jpeg,
    );
    if (out == null) {
      throw Exception('image compression failed for $path');
    }
    return out;
  }

  /// 이미지를 압축 → presigned URL 요청 → S3 업로드 순서로 처리.
  /// [presignEndpoint] 서버의 presign 발급 엔드포인트.
  /// 반환값으로 objectKey 등 이후 서버 등록에 필요한 [PresignResult]를 제공.
  static Future<PresignResult> compressAndUpload({
    required String presignEndpoint,
    required Uint8List imageData,
  }) async {
    // 압축과 presign 요청은 서로 무관 — presign 요청 바디가 고정된
    // contentType/extension만 담아 압축 결과를 필요로 하지 않으므로 병렬 실행.
    // record `.wait`는 실패 시 원본 예외를 ParallelWaitError로 감싸버려서
    // 호출부의 `e is DioException` 판별(networkAwareErrorKey/isDioConflict)이
    // 깨지므로, 이미 시작된 두 Future를 순서대로 await하는 방식으로 병렬성은
    // 유지하되 원본 예외 타입은 그대로 전파되게 함
    final compressFuture = compressToJpeg(imageData);
    final presignFuture = DioClient.dio.post(
      presignEndpoint,
      data: {'contentType': _contentType, 'extension': _ext},
    );
    final compressed = await compressFuture;
    final presignResponse = await presignFuture;
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
