enum SearchType {
  artist,
  festival;
}

class SearchSuggestion {
  final int? id;
  final String label;
  final SearchType type;
  final String? imageUrl;
  const SearchSuggestion(this.label, this.type, {this.id, this.imageUrl});
}
