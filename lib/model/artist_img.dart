

import 'package:freezed_annotation/freezed_annotation.dart';

part 'artist_img.freezed.dart';
part 'artist_img.g.dart';


@freezed
sealed class ArtistImg with _$ArtistImg {
  factory ArtistImg({
    String? docId,
    String? title,
    String? ftvName,
    String? imgUrl,
    int? timestamp,
  }) = _ArtistImg;

  factory ArtistImg.fromJson(Map<String, dynamic> json) =>
      _$ArtistImgFromJson(json);
}