class PresignResult {
  final String uploadUrl;
  final String objectKey;

  PresignResult({required this.uploadUrl, required this.objectKey});

  factory PresignResult.fromJson(Map<String, dynamic> json) {
    return PresignResult(
      uploadUrl: json['uploadUrl'] as String,
      objectKey: json['objectKey'] as String,
    );
  }
}
