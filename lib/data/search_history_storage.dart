import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryStorage {
  SearchHistoryStorage(this._sharedPreferences);

  static const String _historyKey = 'search_history';

  final SharedPreferences _sharedPreferences;

  Future<List<String>> loadHistory() async {
    final history = _sharedPreferences.getStringList(_historyKey) ?? [];
    return List<String>.unmodifiable(
      history.map((keyword) => keyword.trim()).where((keyword) {
        return keyword.isNotEmpty;
      }),
    );
  }

  Future<void> saveHistory(List<String> history) async {
    final didSave = await _sharedPreferences.setStringList(
      _historyKey,
      history,
    );

    if (!didSave) {
      throw const SearchHistoryStorageException(
        'Failed to save search history.',
      );
    }
  }
}

class SearchHistoryStorageException implements Exception {
  const SearchHistoryStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
