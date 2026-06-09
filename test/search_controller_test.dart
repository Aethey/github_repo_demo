import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:github_repository_list_app/features/search/search_provider.dart';
import 'package:github_repository_list_app/features/search/search_state.dart';
import 'package:github_repository_list_app/models/repository_detail.dart';
import 'package:github_repository_list_app/models/repository_search_result.dart';
import 'package:github_repository_list_app/models/repository_summary.dart';
import 'package:github_repository_list_app/providers/repository_providers.dart';
import 'package:github_repository_list_app/repositories/github_repository.dart';

void main() {
  test('SearchController ignores stale responses when query changes', () async {
    final githubRepository = _ControllableGithubRepository();
    final container = ProviderContainer(
      overrides: [githubRepositoryProvider.overrideWithValue(githubRepository)],
    );
    addTearDown(container.dispose);

    final controller = container.read(searchProvider.notifier);

    controller.submit('old-query');
    await _flush();
    controller.submit('new-query');
    await _flush();

    githubRepository.completeSearch(
      query: 'new-query',
      page: 1,
      items: <RepositorySummary>[_summary(2, 'new-owner/new-repository')],
      totalCount: 1,
    );
    await _flush();

    githubRepository.completeSearch(
      query: 'old-query',
      page: 1,
      items: <RepositorySummary>[_summary(1, 'old-owner/old-repository')],
      totalCount: 1,
    );
    await _flush();

    final state = container.read(searchProvider);
    expect(state.status, SearchStatus.data);
    expect(state.query, 'new-query');
    expect(state.repositories, hasLength(1));
    expect(state.repositories.single.fullName, 'new-owner/new-repository');
  });

  test(
    'SearchController paginates once, deduplicates items, and stops at the end',
    () async {
      final githubRepository = _ControllableGithubRepository();
      final container = ProviderContainer(
        overrides: [
          githubRepositoryProvider.overrideWithValue(githubRepository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(searchProvider.notifier);

      controller.submit('flutter');
      await _flush();

      githubRepository.completeSearch(
        query: 'flutter',
        page: 1,
        items: List<RepositorySummary>.generate(
          30,
          (index) => _summary(index + 1, 'owner/repo-${index + 1}'),
        ),
        totalCount: 31,
      );
      await _flush();

      expect(container.read(searchProvider).hasMore, isTrue);

      final nextPageFuture = controller.loadNextPage();
      await _flush();
      await controller.loadNextPage();
      await _flush();

      expect(
        githubRepository.searchRequests.where(
          (request) => request.query == 'flutter' && request.page == 2,
        ),
        hasLength(1),
      );

      githubRepository.completeSearch(
        query: 'flutter',
        page: 2,
        items: <RepositorySummary>[
          _summary(30, 'owner/repo-30'),
          _summary(31, 'owner/repo-31'),
        ],
        totalCount: 31,
      );

      await nextPageFuture;
      await _flush();

      final state = container.read(searchProvider);
      expect(state.status, SearchStatus.data);
      expect(state.page, 2);
      expect(state.repositories, hasLength(31));
      expect(
        state.repositories.map((repository) => repository.id).toSet(),
        hasLength(31),
      );
      expect(state.repositories.last.fullName, 'owner/repo-31');
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    },
  );

  test(
    'SearchController retries next page only when retry is requested',
    () async {
      final githubRepository = _ControllableGithubRepository();
      final container = ProviderContainer(
        overrides: [
          githubRepositoryProvider.overrideWithValue(githubRepository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(searchProvider.notifier);

      controller.submit('flutter');
      await _flush();

      githubRepository.completeSearch(
        query: 'flutter',
        page: 1,
        items: List<RepositorySummary>.generate(
          30,
          (index) => _summary(index + 1, 'owner/repo-${index + 1}'),
        ),
        totalCount: 60,
      );
      await _flush();

      final failedNextPage = controller.loadNextPage();
      await _flush();

      githubRepository.failSearch(
        query: 'flutter',
        page: 2,
        error: Exception('Next page failed.'),
      );
      await failedNextPage;
      await _flush();

      expect(container.read(searchProvider).nextPageErrorMessage, isNotNull);
      expect(
        githubRepository.searchRequests.where(
          (request) => request.query == 'flutter' && request.page == 2,
        ),
        hasLength(1),
      );

      await controller.loadNextPage();
      await _flush();

      expect(
        githubRepository.searchRequests.where(
          (request) => request.query == 'flutter' && request.page == 2,
        ),
        hasLength(1),
      );

      final retryNextPage = controller.loadNextPage(retryAfterError: true);
      await _flush();

      expect(
        githubRepository.searchRequests.where(
          (request) => request.query == 'flutter' && request.page == 2,
        ),
        hasLength(2),
      );

      githubRepository.completeSearch(
        query: 'flutter',
        page: 2,
        items: <RepositorySummary>[_summary(31, 'owner/repo-31')],
        totalCount: 31,
      );
      await retryNextPage;
      await _flush();

      expect(container.read(searchProvider).nextPageErrorMessage, isNull);
    },
  );
}

RepositorySummary _summary(int id, String fullName) {
  return RepositorySummary(
    id: id,
    fullName: fullName,
    ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/$id?v=4',
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _SearchRequest {
  const _SearchRequest({
    required this.query,
    required this.page,
    required this.perPage,
  });

  final String query;
  final int page;
  final int perPage;
}

class _ControllableGithubRepository implements GithubRepository {
  final List<_SearchRequest> searchRequests = <_SearchRequest>[];
  final Map<String, Completer<RepositorySearchResult>> _pendingSearches =
      <String, Completer<RepositorySearchResult>>{};

  @override
  Future<RepositorySearchResult> searchRepositories({
    required String query,
    int page = 1,
    int perPage = 30,
  }) {
    searchRequests.add(
      _SearchRequest(query: query, page: page, perPage: perPage),
    );

    final completer = Completer<RepositorySearchResult>();
    _pendingSearches[_searchKey(query, page)] = completer;
    return completer.future;
  }

  void completeSearch({
    required String query,
    required int page,
    required List<RepositorySummary> items,
    required int totalCount,
  }) {
    final completer = _pendingSearches.remove(_searchKey(query, page));
    if (completer == null) {
      fail('No pending search request for "$query" page $page.');
    }

    completer.complete(
      RepositorySearchResult(items: items, totalCount: totalCount),
    );
  }

  void failSearch({
    required String query,
    required int page,
    required Object error,
  }) {
    final completer = _pendingSearches.remove(_searchKey(query, page));
    if (completer == null) {
      fail('No pending search request for "$query" page $page.');
    }

    completer.completeError(error);
  }

  String _searchKey(String query, int page) {
    return '$query::$page';
  }

  @override
  Future<RepositoryDetail> fetchRepositoryDetail({required String fullName}) {
    throw UnimplementedError();
  }
}
