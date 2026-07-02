// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'open_source_package.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Package {
  String get name;
  String get description;
  String? get homepage;
  String? get repository;
  List<String> get authors;
  String get version;
  String? get license;
  bool get isMarkdown;
  bool get isSdk;
  bool get isDirectDependency;

  /// Create a copy of Package
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PackageCopyWith<Package> get copyWith =>
      _$PackageCopyWithImpl<Package>(this as Package, _$identity);

  /// Serializes this Package to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Package &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.homepage, homepage) ||
                other.homepage == homepage) &&
            (identical(other.repository, repository) ||
                other.repository == repository) &&
            const DeepCollectionEquality().equals(other.authors, authors) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.license, license) || other.license == license) &&
            (identical(other.isMarkdown, isMarkdown) ||
                other.isMarkdown == isMarkdown) &&
            (identical(other.isSdk, isSdk) || other.isSdk == isSdk) &&
            (identical(other.isDirectDependency, isDirectDependency) ||
                other.isDirectDependency == isDirectDependency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      description,
      homepage,
      repository,
      const DeepCollectionEquality().hash(authors),
      version,
      license,
      isMarkdown,
      isSdk,
      isDirectDependency);

  @override
  String toString() {
    return 'Package(name: $name, description: $description, homepage: $homepage, repository: $repository, authors: $authors, version: $version, license: $license, isMarkdown: $isMarkdown, isSdk: $isSdk, isDirectDependency: $isDirectDependency)';
  }
}

/// @nodoc
abstract mixin class $PackageCopyWith<$Res> {
  factory $PackageCopyWith(Package value, $Res Function(Package) _then) =
      _$PackageCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String description,
      String? homepage,
      String? repository,
      List<String> authors,
      String version,
      String? license,
      bool isMarkdown,
      bool isSdk,
      bool isDirectDependency});
}

/// @nodoc
class _$PackageCopyWithImpl<$Res> implements $PackageCopyWith<$Res> {
  _$PackageCopyWithImpl(this._self, this._then);

  final Package _self;
  final $Res Function(Package) _then;

  /// Create a copy of Package
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? homepage = freezed,
    Object? repository = freezed,
    Object? authors = null,
    Object? version = null,
    Object? license = freezed,
    Object? isMarkdown = null,
    Object? isSdk = null,
    Object? isDirectDependency = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      homepage: freezed == homepage
          ? _self.homepage
          : homepage // ignore: cast_nullable_to_non_nullable
              as String?,
      repository: freezed == repository
          ? _self.repository
          : repository // ignore: cast_nullable_to_non_nullable
              as String?,
      authors: null == authors
          ? _self.authors
          : authors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      license: freezed == license
          ? _self.license
          : license // ignore: cast_nullable_to_non_nullable
              as String?,
      isMarkdown: null == isMarkdown
          ? _self.isMarkdown
          : isMarkdown // ignore: cast_nullable_to_non_nullable
              as bool,
      isSdk: null == isSdk
          ? _self.isSdk
          : isSdk // ignore: cast_nullable_to_non_nullable
              as bool,
      isDirectDependency: null == isDirectDependency
          ? _self.isDirectDependency
          : isDirectDependency // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [Package].
extension PackagePatterns on Package {
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
    TResult Function(_Package value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Package() when $default != null:
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
    TResult Function(_Package value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Package():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
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
    TResult? Function(_Package value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Package() when $default != null:
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
    TResult Function(
            String name,
            String description,
            String? homepage,
            String? repository,
            List<String> authors,
            String version,
            String? license,
            bool isMarkdown,
            bool isSdk,
            bool isDirectDependency)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Package() when $default != null:
        return $default(
            _that.name,
            _that.description,
            _that.homepage,
            _that.repository,
            _that.authors,
            _that.version,
            _that.license,
            _that.isMarkdown,
            _that.isSdk,
            _that.isDirectDependency);
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
    TResult Function(
            String name,
            String description,
            String? homepage,
            String? repository,
            List<String> authors,
            String version,
            String? license,
            bool isMarkdown,
            bool isSdk,
            bool isDirectDependency)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Package():
        return $default(
            _that.name,
            _that.description,
            _that.homepage,
            _that.repository,
            _that.authors,
            _that.version,
            _that.license,
            _that.isMarkdown,
            _that.isSdk,
            _that.isDirectDependency);
      case _:
        throw StateError('Unexpected subclass');
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
    TResult? Function(
            String name,
            String description,
            String? homepage,
            String? repository,
            List<String> authors,
            String version,
            String? license,
            bool isMarkdown,
            bool isSdk,
            bool isDirectDependency)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Package() when $default != null:
        return $default(
            _that.name,
            _that.description,
            _that.homepage,
            _that.repository,
            _that.authors,
            _that.version,
            _that.license,
            _that.isMarkdown,
            _that.isSdk,
            _that.isDirectDependency);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Package implements Package {
  _Package(
      {required this.name,
      required this.description,
      this.homepage,
      this.repository,
      required final List<String> authors,
      required this.version,
      this.license,
      required this.isMarkdown,
      required this.isSdk,
      required this.isDirectDependency})
      : _authors = authors;
  factory _Package.fromJson(Map<String, dynamic> json) =>
      _$PackageFromJson(json);

  @override
  final String name;
  @override
  final String description;
  @override
  final String? homepage;
  @override
  final String? repository;
  final List<String> _authors;
  @override
  List<String> get authors {
    if (_authors is EqualUnmodifiableListView) return _authors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_authors);
  }

  @override
  final String version;
  @override
  final String? license;
  @override
  final bool isMarkdown;
  @override
  final bool isSdk;
  @override
  final bool isDirectDependency;

  /// Create a copy of Package
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PackageCopyWith<_Package> get copyWith =>
      __$PackageCopyWithImpl<_Package>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PackageToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Package &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.homepage, homepage) ||
                other.homepage == homepage) &&
            (identical(other.repository, repository) ||
                other.repository == repository) &&
            const DeepCollectionEquality().equals(other._authors, _authors) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.license, license) || other.license == license) &&
            (identical(other.isMarkdown, isMarkdown) ||
                other.isMarkdown == isMarkdown) &&
            (identical(other.isSdk, isSdk) || other.isSdk == isSdk) &&
            (identical(other.isDirectDependency, isDirectDependency) ||
                other.isDirectDependency == isDirectDependency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      description,
      homepage,
      repository,
      const DeepCollectionEquality().hash(_authors),
      version,
      license,
      isMarkdown,
      isSdk,
      isDirectDependency);

  @override
  String toString() {
    return 'Package(name: $name, description: $description, homepage: $homepage, repository: $repository, authors: $authors, version: $version, license: $license, isMarkdown: $isMarkdown, isSdk: $isSdk, isDirectDependency: $isDirectDependency)';
  }
}

/// @nodoc
abstract mixin class _$PackageCopyWith<$Res> implements $PackageCopyWith<$Res> {
  factory _$PackageCopyWith(_Package value, $Res Function(_Package) _then) =
      __$PackageCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String description,
      String? homepage,
      String? repository,
      List<String> authors,
      String version,
      String? license,
      bool isMarkdown,
      bool isSdk,
      bool isDirectDependency});
}

/// @nodoc
class __$PackageCopyWithImpl<$Res> implements _$PackageCopyWith<$Res> {
  __$PackageCopyWithImpl(this._self, this._then);

  final _Package _self;
  final $Res Function(_Package) _then;

  /// Create a copy of Package
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? homepage = freezed,
    Object? repository = freezed,
    Object? authors = null,
    Object? version = null,
    Object? license = freezed,
    Object? isMarkdown = null,
    Object? isSdk = null,
    Object? isDirectDependency = null,
  }) {
    return _then(_Package(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      homepage: freezed == homepage
          ? _self.homepage
          : homepage // ignore: cast_nullable_to_non_nullable
              as String?,
      repository: freezed == repository
          ? _self.repository
          : repository // ignore: cast_nullable_to_non_nullable
              as String?,
      authors: null == authors
          ? _self._authors
          : authors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      license: freezed == license
          ? _self.license
          : license // ignore: cast_nullable_to_non_nullable
              as String?,
      isMarkdown: null == isMarkdown
          ? _self.isMarkdown
          : isMarkdown // ignore: cast_nullable_to_non_nullable
              as bool,
      isSdk: null == isSdk
          ? _self.isSdk
          : isSdk // ignore: cast_nullable_to_non_nullable
              as bool,
      isDirectDependency: null == isDirectDependency
          ? _self.isDirectDependency
          : isDirectDependency // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
