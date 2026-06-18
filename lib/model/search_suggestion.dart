enum SearchType {
  artist,
  festival;
}

class SearchSuggestion {
  final String label;
  final SearchType type;
  const SearchSuggestion(this.label, this.type);
}
