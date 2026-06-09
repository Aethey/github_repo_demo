import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/data/favorite_repository_storage.dart';
import 'package:github_repository_list_app/data/github_api_client.dart';
import 'package:github_repository_list_app/data/search_history_storage.dart';
import 'package:github_repository_list_app/providers/shared_preferences_provider.dart';
import 'package:github_repository_list_app/repositories/favorites_repository.dart';
import 'package:github_repository_list_app/repositories/favorites_repository_impl.dart';
import 'package:github_repository_list_app/repositories/github_repository.dart';
import 'package:github_repository_list_app/repositories/github_repository_impl.dart';
import 'package:github_repository_list_app/repositories/search_history_repository.dart';
import 'package:github_repository_list_app/repositories/search_history_repository_impl.dart';

final githubRepositoryProvider = Provider<GithubRepository>((ref) {
  final githubApiClient = GithubApiClient();
  ref.onDispose(githubApiClient.close);
  return GithubRepositoryImpl(githubApiClient);
});

final favoriteRepositoryStorageProvider = Provider<FavoriteRepositoryStorage>((
  ref,
) {
  return FavoriteRepositoryStorage(ref.watch(sharedPreferencesProvider));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(ref.watch(favoriteRepositoryStorageProvider));
});

final searchHistoryStorageProvider = Provider<SearchHistoryStorage>((ref) {
  return SearchHistoryStorage(ref.watch(sharedPreferencesProvider));
});

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((
  ref,
) {
  return SearchHistoryRepositoryImpl(ref.watch(searchHistoryStorageProvider));
});
