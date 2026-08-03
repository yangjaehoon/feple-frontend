import 'dart:typed_data';

/// 아티스트 사진 업로드 시 함께 다니는 입력값 묶음 (artistId/imageData/title/
/// description/isAnonymous). [PostDraft]와 동일한 목적으로, 서비스 메서드의
/// 실질 파라미터가 3개를 넘어가 파라미터 객체로 묶었다.
class PhotoUploadDraft {
  final int artistId;
  final Uint8List imageData;
  final String title;
  final String description;
  final bool isAnonymous;

  const PhotoUploadDraft({
    required this.artistId,
    required this.imageData,
    required this.title,
    required this.description,
    this.isAnonymous = false,
  });
}
