import 'package:github_repository_list_app/repositories/search_history_repository.dart';
import 'package:github_repository_list_app/data/search_history_storage.dart';

class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  SearchHistoryRepositoryImpl(this._storage);

  final SearchHistoryStorage _storage;

  @override
  Future<List<String>> loadHistory() {
    return _storage.loadHistory();
  }

  @override
  Future<void> saveHistory(List<String> history) {
    return _storage.saveHistory(history);
  }
}
