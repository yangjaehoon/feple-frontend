/// 페스티벌 참여 아티스트 모델
class FestivalArtistItem {
  final int artistId;
  final String artistName;
  final String? profileImageUrl;
  final String? stageName;

  FestivalArtistItem({
    required this.artistId,
    required this.artistName,
    this.profileImageUrl,
    this.stageName,
  });

  String get displayName => artistName;

  factory FestivalArtistItem.fromJson(Map<String, dynamic> json) {
    return FestivalArtistItem(
      artistId: json['artistId'] as int,
      artistName: json['artistName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      stageName: json['stageName'] as String?,
    );
  }
}
