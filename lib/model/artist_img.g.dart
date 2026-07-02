// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_img.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArtistImg _$ArtistImgFromJson(Map<String, dynamic> json) => _ArtistImg(
      docId: json['docId'] as String?,
      title: json['title'] as String?,
      ftvName: json['ftvName'] as String?,
      imgUrl: json['imgUrl'] as String?,
      timestamp: (json['timestamp'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ArtistImgToJson(_ArtistImg instance) =>
    <String, dynamic>{
      'docId': instance.docId,
      'title': instance.title,
      'ftvName': instance.ftvName,
      'imgUrl': instance.imgUrl,
      'timestamp': instance.timestamp,
    };
