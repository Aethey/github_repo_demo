import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/models/favorite_repository.dart';
import 'package:github_repository_list_app/features/favorites/favorite_provider.dart';
import 'package:github_repository_list_app/widgets/repository_tile.dart';
import 'package:github_repository_list_app/features/detail/detail_screen.dart';
import 'package:github_repository_list_app/widgets/empty_view.dart';
import 'package:github_repository_list_app/widgets/error_view.dart';
import 'package:github_repository_list_app/widgets/loading_view.dart';

class StarScreen extends ConsumerWidget {
  const StarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProvider);

    return SafeArea(
      child: favorites.when(
        data: (favoriteState) {
          final repositories = favoriteState.repositories;
          if (repositories.isEmpty) {
            return const EmptyView(
              icon: Icons.star_border,
              title: 'No starred repositories',
              message: 'Repositories you favorite will appear here.',
            );
          }

          return ListView.separated(
            itemCount: repositories.length,
            separatorBuilder: (context, index) => const SizedBox.shrink(),
            itemBuilder: (context, index) {
              final repository = repositories[index];
              return RepositoryTile(
                fullName: repository.fullName,
                ownerAvatarUrl: repository.ownerAvatarUrl,
                isFavorite: true,
                onTap: () => _openDetail(context, repository.fullName),
                onFavoritePressed: () =>
                    _removeFavorite(context, ref, repository),
              );
            },
          );
        },
        loading: () => const LoadingView(message: 'Loading favorites...'),
        error: (error, stackTrace) {
          return ErrorView(
            title: 'Unable to load favorites',
            message: error.toString(),
            onRetry: () => ref.invalidate(favoriteProvider),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, String fullName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DetailScreen(fullName: fullName),
      ),
    );
  }

  Future<void> _removeFavorite(
    BuildContext context,
    WidgetRef ref,
    FavoriteRepository repository,
  ) async {
    try {
      await ref.read(favoriteProvider.notifier).remove(repository.id);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
