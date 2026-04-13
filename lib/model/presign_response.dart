class PresignResponse {
  final String uploadUrl;
  final String objectKey;

  PresignResponse({required this.uploadUrl, required this.objectKey});

  factory PresignResponse.fromJson(Map<String, dynamic> json) {
    return PresignResponse(
      uploadUrl: json['uploadUrl'] as String,
      objectKey: json['objectKey'] as String,
    );
  }
}
