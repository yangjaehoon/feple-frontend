import 'localized_text.dart';

enum SearchType {
  artist,
  festival;

  static SearchType fromValue(String? value) =>
      value == 'artist' ? SearchType.artist : SearchType.festival;
}

class SearchSuggestion {
  final int? id;
  final String label;
  final String labelEn;
  final SearchType type;
  final String? imageUrl;

  const SearchSuggestion(this.label, this.type, {this.id, this.labelEn = '', this.imageUrl});

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) => SearchSuggestion(
        json['label'] as String? ?? '',
        SearchType.fromValue(json['type'] as String?),
        id: (json['id'] as num?)?.toInt(),
        labelEn: json['labelEn'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
      );

  String displayLabel(bool isEnglish) => pickLocalized(isEnglish, label, labelEn);
}
