import 'json_reader.dart';

class PresignResult {
  final String uploadUrl;
  final String objectKey;

  PresignResult({required this.uploadUrl, required this.objectKey});

  factory PresignResult.fromJson(Map<String, dynamic> json) {
    return PresignResult(
      uploadUrl: json.str('uploadUrl'),
      objectKey: json.str('objectKey'),
    );
  }
}
