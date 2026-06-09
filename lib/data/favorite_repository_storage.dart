import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:github_repository_list_app/models/favorite_repository.dart';

class FavoriteRepositoryStorage {
  FavoriteRepositoryStorage(this._sharedPreferences);

  static const String _favoritesKey = 'favorite_repositories';

  final SharedPreferences _sharedPreferences;

  Future<List<FavoriteRepository>> loadFavorites() async {
    final encodedFavorites =
        _sharedPreferences.getStringList(_favoritesKey) ?? const <String>[];

    final favorites = <FavoriteRepository>[];
    for (final encodedFavorite in encodedFavorites) {
      try {
        final decoded = jsonDecode(encodedFavorite);
        if (decoded is Map<String, dynamic>) {
          favorites.add(FavoriteRepository.fromJson(decoded));
        }
      } on FormatException {
        // Ignore a corrupted entry so one bad item does not break the app.
      } on TypeError {
        // Ignore an incompatible entry from older or manually edited storage.
      }
    }

    return List<FavoriteRepository>.unmodifiable(favorites);
  }

  Future<void> saveFavorites(List<FavoriteRepository> favorites) async {
    final encodedFavorites = favorites
        .map((favorite) => jsonEncode(favorite.toJson()))
        .toList(growable: false);

    final didSave = await _sharedPreferences.setStringList(
      _favoritesKey,
      encodedFavorites,
    );

    if (!didSave) {
      throw const FavoriteRepositoryStorageException(
        'Failed to save favorite repositories.',
      );
    }
  }
}

class FavoriteRepositoryStorageException implements Exception {
  const FavoriteRepositoryStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
