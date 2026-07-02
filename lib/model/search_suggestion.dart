enum SearchType {
  artist,
  festival;
}

class SearchSuggestion {
  final int? id;
  final String label;
  final String labelEn;
  final SearchType type;
  final String? imageUrl;

  const SearchSuggestion(this.label, this.type, {this.id, this.labelEn = '', this.imageUrl});

  String displayLabel(bool isEnglish) =>
      isEnglish && labelEn.isNotEmpty ? labelEn : label;
}
