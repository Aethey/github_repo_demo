import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/repositories/favorites_repository.dart';
import 'package:github_repository_list_app/models/favorite_repository.dart';
import 'package:github_repository_list_app/providers/repository_providers.dart';
import 'package:github_repository_list_app/features/favorites/favorite_state.dart';

class FavoriteController extends AsyncNotifier<FavoriteState> {
  FavoritesRepository get _favoritesRepository {
    return ref.read(favoritesRepositoryProvider);
  }

  @override
  FutureOr<FavoriteState> build() async {
    final repositories = await _favoritesRepository.loadFavorites();
    return FavoriteState(repositories: repositories);
  }

  bool contains(int repositoryId) {
    return state.value?.contains(repositoryId) ?? false;
  }

  Future<void> add(FavoriteRepository repository) async {
    final current = await future;
    final next = <FavoriteRepository>[
      ...current.repositories.where((favorite) => favorite.id != repository.id),
      repository,
    ];
    await _replaceFavorites(next);
  }

  Future<void> remove(int repositoryId) async {
    final current = await future;
    final next = current.repositories
        .where((favorite) => favorite.id != repositoryId)
        .toList(growable: false);
    await _replaceFavorites(next);
  }

  Future<void> toggle(FavoriteRepository repository) async {
    if (contains(repository.id)) {
      await remove(repository.id);
      return;
    }
    await add(repository);
  }

  Future<void> _replaceFavorites(List<FavoriteRepository> favorites) async {
    final previous = await future;
    final repositories = List<FavoriteRepository>.unmodifiable(favorites);
    final next = FavoriteState(repositories: repositories);

    state = AsyncData<FavoriteState>(next);
    try {
      await _favoritesRepository.saveFavorites(repositories);
    } on Object catch (error, stackTrace) {
      state = AsyncData<FavoriteState>(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
