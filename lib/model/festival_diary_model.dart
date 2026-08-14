import 'date_format.dart';
import 'localized_text.dart';

enum DiaryVisibility {
  public_('PUBLIC'),
  private_('PRIVATE');

  const DiaryVisibility(this.value);
  final String value;

  static DiaryVisibility fromValue(String? value) => DiaryVisibility.values.firstWhere(
        (v) => v.value == value,
        orElse: () => DiaryVisibility.private_,
      );
}

class FestivalDiaryModel {
  final int id;
  final int festivalId;
  final String festivalTitle;
  final String festivalTitleEn;
  final String content;
  final DiaryVisibility visibility;
  final List<String> photoUrls;
  final String? createdAt;
  final bool isOwner;
  final String? authorNickname;

  const FestivalDiaryModel({
    required this.id,
    required this.festivalId,
    required this.festivalTitle,
    this.festivalTitleEn = '',
    required this.content,
    required this.visibility,
    this.photoUrls = const [],
    this.createdAt,
    this.isOwner = true,
    this.authorNickname,
  });

  factory FestivalDiaryModel.fromJson(Map<String, dynamic> json) =>
      FestivalDiaryModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        festivalId: (json['festivalId'] as num?)?.toInt() ?? 0,
        festivalTitle: json['festivalTitle'] as String? ?? '',
        festivalTitleEn: json['festivalTitleEn'] as String? ?? '',
        content: json['content'] as String? ?? '',
        visibility: DiaryVisibility.fromValue(json['visibility'] as String?),
        photoUrls: (json['photoUrls'] as List?)?.map((e) => e as String).toList() ?? const [],
        createdAt: json['createdAt'] as String?,
        isOwner: json['isOwner'] as bool? ?? true,
        authorNickname: json['authorNickname'] as String?,
      );

  bool get isPublic => visibility == DiaryVisibility.public_;

  String displayFestivalTitle(bool isEnglish) =>
      pickLocalized(isEnglish, festivalTitle, festivalTitleEn);

  String? get formattedDate => formatShortDate(createdAt);
}
