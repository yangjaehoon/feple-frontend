import 'json_reader.dart';
import 'localized_text.dart';

enum SearchType {
  artist,
  festival;

  /// 알 수 없는 값이면 null. 호출부가 폴백을 정한다.
  static SearchType? fromValue(String? value) => switch (value) {
        'artist' => SearchType.artist,
        'festival' => SearchType.festival,
        _ => null,
      };
}

class SearchSuggestion {
  final int? id;
  final String label;
  final String labelEn;
  final SearchType type;
  final String? imageUrl;

  const SearchSuggestion(this.label, this.type, {this.id, this.labelEn = '', this.imageUrl});

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) => SearchSuggestion(
        json.str('label'),
        SearchType.fromValue(json.strOrNull('type')) ?? SearchType.festival,
        id: json.intOrNull('id'),
        labelEn: json.str('labelEn'),
        imageUrl: json.strOrNull('imageUrl'),
      );

  String displayLabel(bool isEnglish) => pickLocalized(isEnglish, label, labelEn);
}
