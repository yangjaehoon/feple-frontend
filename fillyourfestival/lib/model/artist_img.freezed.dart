// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_img.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

ArtistImg _$ArtistImgFromJson(Map<String, dynamic> json) {
  return _ArtistImg.fromJson(json);
}

/// @nodoc
mixin _$ArtistImg {
  String? get docId => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get ftvName => throw _privateConstructorUsedError;
  String? get imgUrl => throw _privateConstructorUsedError;
  int? get timestamp => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistImgCopyWith<ArtistImg> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistImgCopyWith<$Res> {
  factory $ArtistImgCopyWith(ArtistImg value, $Res Function(ArtistImg) then) =
      _$ArtistImgCopyWithImpl<$Res, ArtistImg>;
  @useResult
  $Res call(
      {String? docId,
      String? title,
      String? ftvName,
      String? imgUrl,
      int? timestamp});
}

/// @nodoc
class _$ArtistImgCopyWithImpl<$Res, $Val extends ArtistImg>
    implements $ArtistImgCopyWith<$Res> {
  _$ArtistImgCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? docId = freezed,
    Object? title = freezed,
    Object? ftvName = freezed,
    Object? imgUrl = freezed,
    Object? timestamp = freezed,
  }) {
    return _then(_value.copyWith(
      docId: freezed == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      ftvName: freezed == ftvName
          ? _value.ftvName
          : ftvName // ignore: cast_nullable_to_non_nullable
              as String?,
      imgUrl: freezed == imgUrl
          ? _value.imgUrl
          : imgUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ArtistImgCopyWith<$Res> implements $ArtistImgCopyWith<$Res> {
  factory _$$_ArtistImgCopyWith(
          _$_ArtistImg value, $Res Function(_$_ArtistImg) then) =
      __$$_ArtistImgCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? docId,
      String? title,
      String? ftvName,
      String? imgUrl,
      int? timestamp});
}

/// @nodoc
class __$$_ArtistImgCopyWithImpl<$Res>
    extends _$ArtistImgCopyWithImpl<$Res, _$_ArtistImg>
    implements _$$_ArtistImgCopyWith<$Res> {
  __$$_ArtistImgCopyWithImpl(
      _$_ArtistImg _value, $Res Function(_$_ArtistImg) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? docId = freezed,
    Object? title = freezed,
    Object? ftvName = freezed,
    Object? imgUrl = freezed,
    Object? timestamp = freezed,
  }) {
    return _then(_$_ArtistImg(
      docId: freezed == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      ftvName: freezed == ftvName
          ? _value.ftvName
          : ftvName // ignore: cast_nullable_to_non_nullable
              as String?,
      imgUrl: freezed == imgUrl
          ? _value.imgUrl
          : imgUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ArtistImg implements _ArtistImg {
  _$_ArtistImg(
      {this.docId, this.title, this.ftvName, this.imgUrl, this.timestamp});

  factory _$_ArtistImg.fromJson(Map<String, dynamic> json) =>
      _$$_ArtistImgFromJson(json);

  @override
  final String? docId;
  @override
  final String? title;
  @override
  final String? ftvName;
  @override
  final String? imgUrl;
  @override
  final int? timestamp;

  @override
  String toString() {
    return 'ArtistImg(docId: $docId, title: $title, ftvName: $ftvName, imgUrl: $imgUrl, timestamp: $timestamp)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ArtistImg &&
            (identical(other.docId, docId) || other.docId == docId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.ftvName, ftvName) || other.ftvName == ftvName) &&
            (identical(other.imgUrl, imgUrl) || other.imgUrl == imgUrl) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, docId, title, ftvName, imgUrl, timestamp);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ArtistImgCopyWith<_$_ArtistImg> get copyWith =>
      __$$_ArtistImgCopyWithImpl<_$_ArtistImg>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ArtistImgToJson(
      this,
    );
  }
}

abstract class _ArtistImg implements ArtistImg {
  factory _ArtistImg(
      {final String? docId,
      final String? title,
      final String? ftvName,
      final String? imgUrl,
      final int? timestamp}) = _$_ArtistImg;

  factory _ArtistImg.fromJson(Map<String, dynamic> json) =
      _$_ArtistImg.fromJson;

  @override
  String? get docId;
  @override
  String? get title;
  @override
  String? get ftvName;
  @override
  String? get imgUrl;
  @override
  int? get timestamp;
  @override
  @JsonKey(ignore: true)
  _$$_ArtistImgCopyWith<_$_ArtistImg> get copyWith =>
      throw _privateConstructorUsedError;
}
