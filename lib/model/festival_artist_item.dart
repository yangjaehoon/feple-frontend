import 'json_reader.dart';
import 'localized_text.dart';

/// 페스티벌 참여 아티스트 모델
class FestivalArtistItem {
  final int artistId;
  final String artistName;
  final String artistNameEn;
  final String? profileImageUrl;
  final String? stageName;
  final List<String> performanceDates;

  FestivalArtistItem({
    required this.artistId,
    required this.artistName,
    this.artistNameEn = '',
    this.profileImageUrl,
    this.stageName,
    this.performanceDates = const [],
  });

  String displayName(bool isEnglish) => pickLocalized(isEnglish, artistName, artistNameEn);

  Map<String, dynamic> toJson() => {
        'artistId': artistId,
        'artistName': artistName,
        'artistNameEn': artistNameEn,
        'profileImageUrl': profileImageUrl,
        'stageName': stageName,
        'performanceDates': performanceDates,
      };

  factory FestivalArtistItem.fromJson(Map<String, dynamic> json) {
    return FestivalArtistItem(
      artistId: json.integer('artistId'),
      artistName: json.str('artistName'),
      artistNameEn: json.str('artistNameEn'),
      profileImageUrl: json.strOrNull('profileImageUrl'),
      stageName: json.strOrNull('stageName'),
      performanceDates: json.stringList('performanceDates'),
    );
  }
}
