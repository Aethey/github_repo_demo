import 'package:github_repository_list_app/models/favorite_repository.dart';

class FavoriteState {
  const FavoriteState({required this.repositories});

  factory FavoriteState.empty() {
    return const FavoriteState(repositories: <FavoriteRepository>[]);
  }

  final List<FavoriteRepository> repositories;

  bool contains(int repositoryId) {
    return repositories.any((repository) => repository.id == repositoryId);
  }

  FavoriteState copyWith({List<FavoriteRepository>? repositories}) {
    return FavoriteState(repositories: repositories ?? this.repositories);
  }
}
