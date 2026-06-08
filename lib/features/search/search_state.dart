import 'package:github_repository_list_app/models/repository_summary.dart';

enum SearchStatus { home, loading, data, empty, error }

class SearchState {
  const SearchState._({
    required this.query,
    required this.status,
    required this.repositories,
    required this.page,
    required this.totalCount,
    required this.hasMore,
    required this.isLoadingMore,
    this.errorMessage,
    this.nextPageErrorMessage,
  });

  factory SearchState.home() {
    return const SearchState._(
      query: '',
      status: SearchStatus.home,
      repositories: <RepositorySummary>[],
      page: 0,
      totalCount: 0,
      hasMore: false,
      isLoadingMore: false,
    );
  }

  factory SearchState.loading(String query) {
    return SearchState._(
      query: query,
      status: SearchStatus.loading,
      repositories: const <RepositorySummary>[],
      page: 0,
      totalCount: 0,
      hasMore: false,
      isLoadingMore: false,
    );
  }

  factory SearchState.result({
    required String query,
    required List<RepositorySummary> repositories,
    required int page,
    required int totalCount,
    required bool hasMore,
  }) {
    return SearchState._(
      query: query,
      status: repositories.isEmpty ? SearchStatus.empty : SearchStatus.data,
      repositories: List<RepositorySummary>.unmodifiable(repositories),
      page: page,
      totalCount: totalCount,
      hasMore: hasMore,
      isLoadingMore: false,
    );
  }

  factory SearchState.error({required String query, required String message}) {
    return SearchState._(
      query: query,
      status: SearchStatus.error,
      repositories: const <RepositorySummary>[],
      page: 0,
      totalCount: 0,
      hasMore: false,
      isLoadingMore: false,
      errorMessage: message,
    );
  }

  final String query;
  final SearchStatus status;
  final List<RepositorySummary> repositories;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? nextPageErrorMessage;

  static const Object _noValue = Object();

  SearchState copyWith({
    String? query,
    SearchStatus? status,
    List<RepositorySummary>? repositories,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? isLoadingMore,
    Object? errorMessage = _noValue,
    Object? nextPageErrorMessage = _noValue,
  }) {
    return SearchState._(
      query: query ?? this.query,
      status: status ?? this.status,
      repositories: repositories ?? this.repositories,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage == _noValue
          ? this.errorMessage
          : errorMessage as String?,
      nextPageErrorMessage: nextPageErrorMessage == _noValue
          ? this.nextPageErrorMessage
          : nextPageErrorMessage as String?,
    );
  }
}
