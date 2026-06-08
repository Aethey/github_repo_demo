import 'package:github_repository_list_app/models/favorite_repository.dart';

abstract interface class FavoritesRepository {
  Future<List<FavoriteRepository>> loadFavorites();

  Future<void> saveFavorites(List<FavoriteRepository> favorites);
}
