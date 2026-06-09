import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/config/github_api_config.dart';
import 'package:github_repository_list_app/repositories/github_repository.dart';
import 'package:github_repository_list_app/models/repository_summary.dart';
import 'package:github_repository_list_app/providers/repository_providers.dart';
import 'package:github_repository_list_app/features/search/search_state.dart';

class SearchController extends Notifier<SearchState> {
  int _activeRequestId = 0;

  GithubRepository get _githubRepository {
    return ref.read(githubRepositoryProvider);
  }

  @override
  SearchState build() {
    return SearchState.home();
  }

  void inputChanged(String value) {
    final query = value.trim();
    if (query == state.query && state.status != SearchStatus.error) {
      return;
    }

    _activeRequestId++;
    state = SearchState.home();
  }

  void submit(String value) {
    final query = value.trim();
    _activeRequestId++;

    if (query.isEmpty) {
      state = SearchState.home();
      return;
    }

    final requestId = _activeRequestId;
    state = SearchState.loading(query);
    unawaited(_searchFirstPage(query, requestId: requestId));
  }

  void retry() {
    final query = state.query.trim();
    if (query.isEmpty) {
      state = SearchState.home();
      return;
    }

    _activeRequestId++;
    final requestId = _activeRequestId;
    unawaited(_searchFirstPage(query, requestId: requestId));
  }

  Future<void> refresh() async {
    final current = state;
    final query = current.query.trim();
    if (query.isEmpty) {
      return;
    }

    _activeRequestId++;
    final requestId = _activeRequestId;

    if (current.status == SearchStatus.data) {
      state = current.copyWith(
        isLoadingMore: false,
        nextPageErrorMessage: null,
      );
      await _searchFirstPage(query, requestId: requestId, showLoading: false);
      return;
    }

    await _searchFirstPage(query, requestId: requestId);
  }

  Future<void> loadNextPage() async {
    final current = state;
    if (current.status != SearchStatus.data ||
        current.isLoadingMore ||
        !current.hasMore ||
        current.query.isEmpty) {
      return;
    }

    final requestId = _activeRequestId;
    final query = current.query;
    final nextPage = current.page + 1;

    state = current.copyWith(isLoadingMore: true, nextPageErrorMessage: null);

    try {
      final result = await _githubRepository.searchRepositories(
        query: query,
        page: nextPage,
        perPage: GithubApiConfig.defaultSearchPerPage,
      );

      if (!_isCurrentRequest(requestId, query)) {
        return;
      }

      final existingIds = state.repositories.map((item) => item.id).toSet();
      final combined = <RepositorySummary>[
        ...state.repositories,
        for (final item in result.items)
          if (existingIds.add(item.id)) item,
      ];

      state = state.copyWith(
        repositories: List<RepositorySummary>.unmodifiable(combined),
        page: nextPage,
        totalCount: result.totalCount,
        hasMore: _hasMore(
          loadedCount: combined.length,
          totalCount: result.totalCount,
          lastPageItemCount: result.items.length,
        ),
        isLoadingMore: false,
        nextPageErrorMessage: null,
      );
    } on Object catch (error) {
      if (!_isCurrentRequest(requestId, query)) {
        return;
      }

      state = state.copyWith(
        isLoadingMore: false,
        nextPageErrorMessage: _friendlyMessage(error),
      );
    }
  }

  Future<void> _searchFirstPage(
    String query, {
    required int requestId,
    bool showLoading = true,
  }) async {
    if (!_isCurrentRequest(requestId, query)) {
      return;
    }

    if (showLoading) {
      state = SearchState.loading(query);
    }

    try {
      final result = await _githubRepository.searchRepositories(
        query: query,
        page: 1,
        perPage: GithubApiConfig.defaultSearchPerPage,
      );

      if (!_isCurrentRequest(requestId, query)) {
        return;
      }

      final items = List<RepositorySummary>.unmodifiable(result.items);
      state = SearchState.result(
        query: query,
        repositories: items,
        page: 1,
        totalCount: result.totalCount,
        hasMore: _hasMore(
          loadedCount: items.length,
          totalCount: result.totalCount,
          lastPageItemCount: items.length,
        ),
      );
    } on Object catch (error) {
      if (!_isCurrentRequest(requestId, query)) {
        return;
      }

      state = SearchState.error(query: query, message: _friendlyMessage(error));
    }
  }

  bool _isCurrentRequest(int requestId, String query) {
    return requestId == _activeRequestId && query == state.query;
  }

  bool _hasMore({
    required int loadedCount,
    required int totalCount,
    required int lastPageItemCount,
  }) {
    final accessibleTotal = totalCount > GithubApiConfig.searchResultLimit
        ? GithubApiConfig.searchResultLimit
        : totalCount;
    return lastPageItemCount == GithubApiConfig.defaultSearchPerPage &&
        loadedCount < accessibleTotal;
  }

  String _friendlyMessage(Object error) {
    final message = error.toString();
    if (message.isNotEmpty) {
      return message;
    }
    return 'Something went wrong. Please try again.';
  }
}
