abstract interface class SearchHistoryRepository {
  Future<List<String>> loadHistory();

  Future<void> saveHistory(List<String> history);
}
