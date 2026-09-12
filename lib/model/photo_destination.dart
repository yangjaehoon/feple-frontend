import 'package:feple/model/festival_preview.dart';

/// 아티스트 사진의 출처 선택지 — 실제 페스티벌이거나 고정 카테고리(일상/SNS/기타).
/// 이전에는 음수 ID(-1/-2/-3)를 가진 가짜 FestivalPreview로 표현했음.
sealed class PhotoDestination {
  const PhotoDestination();

  /// 서버에 저장되는 description 문자열
  String get description;

  static const daily = PhotoCategory._(PhotoCategoryKind.daily, '일상 사진');
  static const sns = PhotoCategory._(PhotoCategoryKind.sns, 'SNS 사진');
  static const other = PhotoCategory._(PhotoCategoryKind.other, '');
  static const categories = [daily, sns, other];

  factory PhotoDestination.fromDescription(
      String desc, List<FestivalPreview> festivals) {
    if (desc == daily.description) return daily;
    if (desc == sns.description) return sns;
    if (desc.isEmpty) return other;
    for (final f in festivals) {
      if (f.title == desc) return FestivalDestination(f);
    }
    return other;
  }
}

class FestivalDestination extends PhotoDestination {
  final FestivalPreview festival;
  const FestivalDestination(this.festival);

  @override
  String get description => festival.title;

  @override
  bool operator ==(Object other) =>
      other is FestivalDestination && other.festival.id == festival.id;

  @override
  int get hashCode => festival.id.hashCode;
}

/// 표시용 라벨(i18n key)은 모델 레이어에 두지 않는다 — `PhotoCategoryStyle`
/// extension(`lib/screen/main/tab/search/artist_page/image_collection/photo_category_style.dart`) 참조.
enum PhotoCategoryKind { daily, sns, other }

class PhotoCategory extends PhotoDestination {
  final PhotoCategoryKind kind;
  final String _rawDescription;
  const PhotoCategory._(this.kind, this._rawDescription);

  @override
  String get description => _rawDescription;
}
