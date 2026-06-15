// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_img.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_ArtistImg _$$_ArtistImgFromJson(Map<String, dynamic> json) => _$_ArtistImg(
      docId: json['docId'] as String?,
      title: json['title'] as String?,
      ftvName: json['ftvName'] as String?,
      imgUrl: json['imgUrl'] as String?,
      timestamp: json['timestamp'] as int?,
    );

Map<String, dynamic> _$$_ArtistImgToJson(_$_ArtistImg instance) =>
    <String, dynamic>{
      'docId': instance.docId,
      'title': instance.title,
      'ftvName': instance.ftvName,
      'imgUrl': instance.imgUrl,
      'timestamp': instance.timestamp,
    };
