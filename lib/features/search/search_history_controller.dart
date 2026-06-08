import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/config/app_config.dart';
import 'package:github_repository_list_app/features/search/search_history_state.dart';
import 'package:github_repository_list_app/providers/repository_providers.dart';
import 'package:github_repository_list_app/repositories/search_history_repository.dart';

class SearchHistoryController extends AsyncNotifier<SearchHistoryState> {
  SearchHistoryRepository get _searchHistoryRepository {
    return ref.read(searchHistoryRepositoryProvider);
  }

  @override
  FutureOr<SearchHistoryState> build() async {
    final keywords = await _searchHistoryRepository.loadHistory();
    return SearchHistoryState(keywords: _latestKeywords(keywords));
  }

  Future<void> add(String keyword) async {
    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      return;
    }

    final current = await future;
    final next = <String>[
      normalizedKeyword,
      ...current.keywords.where(
        (item) => item.toLowerCase() != normalizedKeyword.toLowerCase(),
      ),
    ];

    await _replaceHistory(_latestKeywords(next));
  }

  Future<void> remove(String keyword) async {
    final current = await future;
    final next = current.keywords
        .where((item) => item != keyword)
        .toList(growable: false);
    await _replaceHistory(next);
  }

  Future<void> clear() async {
    await _replaceHistory(const <String>[]);
  }

  Future<void> _replaceHistory(List<String> history) async {
    final previous = await future;
    final keywords = _latestKeywords(history);
    final next = SearchHistoryState(keywords: keywords);

    state = AsyncData<SearchHistoryState>(next);
    try {
      await _searchHistoryRepository.saveHistory(keywords);
    } on Object catch (error, stackTrace) {
      state = AsyncData<SearchHistoryState>(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  List<String> _latestKeywords(List<String> history) {
    return List<String>.unmodifiable(
      history
          .map((keyword) => keyword.trim())
          .where((keyword) => keyword.isNotEmpty)
          .take(AppConfig.searchHistoryLimit),
    );
  }
}
