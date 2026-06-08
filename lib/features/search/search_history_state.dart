class SearchHistoryState {
  const SearchHistoryState({required this.keywords});

  factory SearchHistoryState.empty() {
    return const SearchHistoryState(keywords: <String>[]);
  }

  final List<String> keywords;
}
