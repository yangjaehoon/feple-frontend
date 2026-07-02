// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_img.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArtistImg {
  String? get docId;
  String? get title;
  String? get ftvName;
  String? get imgUrl;
  int? get timestamp;

  /// Create a copy of ArtistImg
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ArtistImgCopyWith<ArtistImg> get copyWith =>
      _$ArtistImgCopyWithImpl<ArtistImg>(this as ArtistImg, _$identity);

  /// Serializes this ArtistImg to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ArtistImg &&
            (identical(other.docId, docId) || other.docId == docId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.ftvName, ftvName) || other.ftvName == ftvName) &&
            (identical(other.imgUrl, imgUrl) || other.imgUrl == imgUrl) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, docId, title, ftvName, imgUrl, timestamp);

  @override
  String toString() {
    return 'ArtistImg(docId: $docId, title: $title, ftvName: $ftvName, imgUrl: $imgUrl, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $ArtistImgCopyWith<$Res> {
  factory $ArtistImgCopyWith(ArtistImg value, $Res Function(ArtistImg) _then) =
      _$ArtistImgCopyWithImpl;
  @useResult
  $Res call(
      {String? docId,
      String? title,
      String? ftvName,
      String? imgUrl,
      int? timestamp});
}

/// @nodoc
class _$ArtistImgCopyWithImpl<$Res> implements $ArtistImgCopyWith<$Res> {
  _$ArtistImgCopyWithImpl(this._self, this._then);

  final ArtistImg _self;
  final $Res Function(ArtistImg) _then;

  /// Create a copy of ArtistImg
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? docId = freezed,
    Object? title = freezed,
    Object? ftvName = freezed,
    Object? imgUrl = freezed,
    Object? timestamp = freezed,
  }) {
    return _then(_self.copyWith(
      docId: freezed == docId
          ? _self.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      ftvName: freezed == ftvName
          ? _self.ftvName
          : ftvName // ignore: cast_nullable_to_non_nullable
              as String?,
      imgUrl: freezed == imgUrl
          ? _self.imgUrl
          : imgUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: freezed == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ArtistImg].
extension ArtistImgPatterns on ArtistImg {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ArtistImg value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ArtistImg() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ArtistImg value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ArtistImg():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ArtistImg value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ArtistImg() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String? docId, String? title, String? ftvName,
            String? imgUrl, int? timestamp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ArtistImg() when $default != null:
        return $default(_that.docId, _that.title, _that.ftvName, _that.imgUrl,
            _that.timestamp);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String? docId, String? title, String? ftvName,
            String? imgUrl, int? timestamp)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ArtistImg():
        return $default(_that.docId, _that.title, _that.ftvName, _that.imgUrl,
            _that.timestamp);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String? docId, String? title, String? ftvName,
            String? imgUrl, int? timestamp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ArtistImg() when $default != null:
        return $default(_that.docId, _that.title, _that.ftvName, _that.imgUrl,
            _that.timestamp);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ArtistImg implements ArtistImg {
  _ArtistImg(
      {this.docId, this.title, this.ftvName, this.imgUrl, this.timestamp});
  factory _ArtistImg.fromJson(Map<String, dynamic> json) =>
      _$ArtistImgFromJson(json);

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

  /// Create a copy of ArtistImg
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ArtistImgCopyWith<_ArtistImg> get copyWith =>
      __$ArtistImgCopyWithImpl<_ArtistImg>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ArtistImgToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ArtistImg &&
            (identical(other.docId, docId) || other.docId == docId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.ftvName, ftvName) || other.ftvName == ftvName) &&
            (identical(other.imgUrl, imgUrl) || other.imgUrl == imgUrl) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, docId, title, ftvName, imgUrl, timestamp);

  @override
  String toString() {
    return 'ArtistImg(docId: $docId, title: $title, ftvName: $ftvName, imgUrl: $imgUrl, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$ArtistImgCopyWith<$Res>
    implements $ArtistImgCopyWith<$Res> {
  factory _$ArtistImgCopyWith(
          _ArtistImg value, $Res Function(_ArtistImg) _then) =
      __$ArtistImgCopyWithImpl;
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
class __$ArtistImgCopyWithImpl<$Res> implements _$ArtistImgCopyWith<$Res> {
  __$ArtistImgCopyWithImpl(this._self, this._then);

  final _ArtistImg _self;
  final $Res Function(_ArtistImg) _then;

  /// Create a copy of ArtistImg
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? docId = freezed,
    Object? title = freezed,
    Object? ftvName = freezed,
    Object? imgUrl = freezed,
    Object? timestamp = freezed,
  }) {
    return _then(_ArtistImg(
      docId: freezed == docId
          ? _self.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      ftvName: freezed == ftvName
          ? _self.ftvName
          : ftvName // ignore: cast_nullable_to_non_nullable
              as String?,
      imgUrl: freezed == imgUrl
          ? _self.imgUrl
          : imgUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: freezed == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
