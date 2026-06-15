/// 페스티벌 참여 아티스트 모델
class FestivalArtistItem {
  final int artistId;
  final String artistName;
  final String? profileImageUrl;
  final String? stageName;
  final List<String> performanceDates;

  FestivalArtistItem({
    required this.artistId,
    required this.artistName,
    this.profileImageUrl,
    this.stageName,
    this.performanceDates = const [],
  });

  Map<String, dynamic> toJson() => {
        'artistId': artistId,
        'artistName': artistName,
        'profileImageUrl': profileImageUrl,
        'stageName': stageName,
        'performanceDates': performanceDates,
      };

  factory FestivalArtistItem.fromJson(Map<String, dynamic> json) {
    return FestivalArtistItem(
      artistId: json['artistId'] as int,
      artistName: json['artistName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      stageName: json['stageName'] as String?,
      performanceDates: (json['performanceDates'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}
