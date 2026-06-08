import 'package:github_repository_list_app/data/favorite_repository_storage.dart';
import 'package:github_repository_list_app/repositories/favorites_repository.dart';
import 'package:github_repository_list_app/models/favorite_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._storage);

  final FavoriteRepositoryStorage _storage;

  @override
  Future<List<FavoriteRepository>> loadFavorites() {
    return _storage.loadFavorites();
  }

  @override
  Future<void> saveFavorites(List<FavoriteRepository> favorites) {
    return _storage.saveFavorites(favorites);
  }
}
