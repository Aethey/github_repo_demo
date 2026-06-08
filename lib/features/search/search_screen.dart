import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/models/favorite_repository.dart';
import 'package:github_repository_list_app/features/favorites/favorite_provider.dart';
import 'package:github_repository_list_app/models/repository_summary.dart';
import 'package:github_repository_list_app/widgets/repository_tile.dart';
import 'package:github_repository_list_app/features/detail/detail_screen.dart';
import 'package:github_repository_list_app/features/search/search_history_provider.dart';
import 'package:github_repository_list_app/features/search/search_provider.dart';
import 'package:github_repository_list_app/features/search/search_state.dart';
import 'package:github_repository_list_app/widgets/empty_view.dart';
import 'package:github_repository_list_app/widgets/error_view.dart';
import 'package:github_repository_list_app/widgets/loading_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _textController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final searchHistory = ref.watch(searchHistoryProvider);
    final favorites = ref.watch(favoriteProvider);
    final favoriteIds =
        favorites.value?.repositories.map((favorite) => favorite.id).toSet() ??
        <int>{};

    return SafeArea(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              key: const ValueKey<String>('repository-search-field'),
              controller: _textController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search repositories',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                suffixIcon: _textController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.6,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                ref.read(searchProvider.notifier).inputChanged(value);
              },
              onTapOutside: (_) {
                _searchFocusNode.unfocus();
              },
              onSubmitted: _executeSearch,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: _SearchContent(
                        searchState: searchState,
                        favoriteIds: favoriteIds,
                        favoritesReady: favorites.hasValue,
                        scrollController: _scrollController,
                        onRepositoryTap: _openDetail,
                        onFavoritePressed: _toggleFavorite,
                        onRetrySearch: () {
                          ref.read(searchProvider.notifier).retry();
                        },
                        onRetryNextPage: () {
                          ref.read(searchProvider.notifier).loadNextPage();
                        },
                        onRefreshSearch: () {
                          return ref.read(searchProvider.notifier).refresh();
                        },
                      ),
                    ),
                    if (_searchFocusNode.hasFocus)
                      Positioned(
                        top: 0,
                        left: 12,
                        right: 12,
                        child: searchHistory.when(
                          data: (historyState) {
                            final history = historyState.keywords;
                            if (history.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return TextFieldTapRegion(
                              child: _SearchHistoryPanel(
                                history: history,
                                maxHeight: constraints.maxHeight * 2 / 3,
                                onSelected: _executeSearch,
                                onDeleted: _deleteSearchHistory,
                                onCleared: _clearSearchHistory,
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.extentAfter < 480) {
      ref.read(searchProvider.notifier).loadNextPage();
    }
  }

  void _onSearchFocusChanged() {
    setState(() {});
  }

  void _clearSearch() {
    _textController.clear();
    setState(() {});
    ref.read(searchProvider.notifier).inputChanged('');
  }

  Future<void> _executeSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    _textController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _searchFocusNode.unfocus();
    setState(() {});
    ref.read(searchProvider.notifier).submit(query);

    try {
      await ref.read(searchHistoryProvider.notifier).add(query);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteSearchHistory(String keyword) async {
    try {
      await ref.read(searchHistoryProvider.notifier).remove(keyword);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _clearSearchHistory() async {
    try {
      await ref.read(searchHistoryProvider.notifier).clear();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _openDetail(String fullName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DetailScreen(fullName: fullName),
      ),
    );
  }

  Future<void> _toggleFavorite(RepositorySummary repository) async {
    try {
      await ref
          .read(favoriteProvider.notifier)
          .toggle(FavoriteRepository.fromSummary(repository));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _SearchHistoryPanel extends StatelessWidget {
  const _SearchHistoryPanel({
    required this.history,
    required this.maxHeight,
    required this.onSelected,
    required this.onDeleted,
    required this.onCleared,
  });

  final List<String> history;
  final double maxHeight;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onDeleted;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const headerHeight = 36.0;
    const itemHeight = 52.0;
    const footerHeight = 52.0;
    final desiredHeight =
        headerHeight + (history.length * itemHeight) + footerHeight;
    final panelHeight = desiredHeight > maxHeight
        ? maxHeight
        : desiredHeight.toDouble();

    return Material(
      elevation: 3,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: panelHeight,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          children: <Widget>[
            Container(
              height: headerHeight,
              width: double.infinity,
              color: colorScheme.surfaceContainerHighest,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recent searches',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: history.length,
                separatorBuilder: (context, index) {
                  return const SizedBox.shrink();
                },
                itemBuilder: (context, index) {
                  final keyword = history[index];
                  return InkWell(
                    onTap: () => onSelected(keyword),
                    child: SizedBox(
                      height: 52,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 6),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.search,
                              size: 19,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                keyword,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete search record',
                              onPressed: () => onDeleted(keyword),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 52,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: onCleared,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Clear history'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchContent extends StatelessWidget {
  const _SearchContent({
    required this.searchState,
    required this.favoriteIds,
    required this.favoritesReady,
    required this.scrollController,
    required this.onRepositoryTap,
    required this.onFavoritePressed,
    required this.onRetrySearch,
    required this.onRetryNextPage,
    required this.onRefreshSearch,
  });

  final SearchState searchState;
  final Set<int> favoriteIds;
  final bool favoritesReady;
  final ScrollController scrollController;
  final ValueChanged<String> onRepositoryTap;
  final ValueChanged<RepositorySummary> onFavoritePressed;
  final VoidCallback onRetrySearch;
  final VoidCallback onRetryNextPage;
  final RefreshCallback onRefreshSearch;

  @override
  Widget build(BuildContext context) {
    switch (searchState.status) {
      case SearchStatus.home:
        return const EmptyView(
          icon: Icons.manage_search,
          title: 'Search GitHub repositories',
          message: 'Enter a keyword to find public repositories on GitHub.',
        );
      case SearchStatus.loading:
        return const LoadingView(message: 'Searching repositories...');
      case SearchStatus.empty:
        return EmptyView(
          icon: Icons.search_off,
          title: 'No repositories found',
          message: 'No results matched "${searchState.query}".',
        );
      case SearchStatus.error:
        return ErrorView(
          title: 'Search failed',
          message:
              'Could not load results for "${searchState.query}".\n'
              '${searchState.errorMessage ?? 'Please try again.'}',
          onRetry: onRetrySearch,
        );
      case SearchStatus.data:
        return _RepositoryResultList(
          searchState: searchState,
          favoriteIds: favoriteIds,
          favoritesReady: favoritesReady,
          scrollController: scrollController,
          onRepositoryTap: onRepositoryTap,
          onFavoritePressed: onFavoritePressed,
          onRetryNextPage: onRetryNextPage,
          onRefreshSearch: onRefreshSearch,
        );
    }
  }
}

class _RepositoryResultList extends StatelessWidget {
  const _RepositoryResultList({
    required this.searchState,
    required this.favoriteIds,
    required this.favoritesReady,
    required this.scrollController,
    required this.onRepositoryTap,
    required this.onFavoritePressed,
    required this.onRetryNextPage,
    required this.onRefreshSearch,
  });

  final SearchState searchState;
  final Set<int> favoriteIds;
  final bool favoritesReady;
  final ScrollController scrollController;
  final ValueChanged<String> onRepositoryTap;
  final ValueChanged<RepositorySummary> onFavoritePressed;
  final VoidCallback onRetryNextPage;
  final RefreshCallback onRefreshSearch;

  @override
  Widget build(BuildContext context) {
    final repositories = searchState.repositories;
    final showFooter =
        searchState.isLoadingMore ||
        searchState.nextPageErrorMessage != null ||
        !searchState.hasMore;

    return RefreshIndicator(
      onRefresh: onRefreshSearch,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: repositories.length + (showFooter ? 1 : 0),
        separatorBuilder: (context, index) {
          return const SizedBox.shrink();
        },
        itemBuilder: (context, index) {
          if (index >= repositories.length) {
            return _PaginationFooter(
              searchState: searchState,
              onRetryNextPage: onRetryNextPage,
            );
          }

          final repository = repositories[index];
          return RepositoryTile(
            fullName: repository.fullName,
            ownerAvatarUrl: repository.ownerAvatarUrl,
            isFavorite: favoriteIds.contains(repository.id),
            favoriteEnabled: favoritesReady,
            onTap: () => onRepositoryTap(repository.fullName),
            onFavoritePressed: () => onFavoritePressed(repository),
          );
        },
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.searchState,
    required this.onRetryNextPage,
  });

  final SearchState searchState;
  final VoidCallback onRetryNextPage;

  @override
  Widget build(BuildContext context) {
    final nextPageErrorMessage = searchState.nextPageErrorMessage;
    if (searchState.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (nextPageErrorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              nextPageErrorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetryNextPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'No more repositories',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
