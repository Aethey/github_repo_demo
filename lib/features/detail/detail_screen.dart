import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/models/favorite_repository.dart';
import 'package:github_repository_list_app/features/favorites/favorite_provider.dart';
import 'package:github_repository_list_app/models/repository_name_parts.dart';
import 'package:github_repository_list_app/models/repository_detail.dart';
import 'package:github_repository_list_app/widgets/repository_tile.dart';
import 'package:github_repository_list_app/features/detail/detail_provider.dart';
import 'package:github_repository_list_app/widgets/error_view.dart';
import 'package:github_repository_list_app/widgets/loading_view.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.fullName});

  final String fullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(detailProvider(fullName));

    return Scaffold(
      appBar: AppBar(title: const Text('Repository Detail')),
      body: SafeArea(
        child: detail.when(
          data: (detailState) =>
              _DetailBody(repository: detailState.repository),
          loading: () => const LoadingView(message: 'Loading repository...'),
          error: (error, stackTrace) => ErrorView(
            title: 'Unable to load repository',
            message: error.toString(),
            onRetry: () => ref.invalidate(detailProvider(fullName)),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.repository});

  final RepositoryDetail repository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProvider);
    final name = RepositoryNameParts.fromFullName(repository.fullName);
    final isFavorite =
        favorites.value?.repositories.any(
          (favorite) => favorite.id == repository.id,
        ) ??
        false;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    RepositoryAvatar(url: repository.ownerAvatarUrl, size: 76),
                    const SizedBox(width: 16),
                    Expanded(child: _RepositoryIdentity(name: name)),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _DetailFavoriteButton(
                        isFavorite: isFavorite,
                        enabled: favorites.hasValue,
                        onPressed: () =>
                            _toggleFavorite(context, ref, repository),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SubscribersRow(count: repository.subscribersCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    RepositoryDetail repository,
  ) async {
    try {
      await ref
          .read(favoriteProvider.notifier)
          .toggle(FavoriteRepository.fromDetail(repository));
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

class _RepositoryIdentity extends StatelessWidget {
  const _RepositoryIdentity({required this.name});

  final RepositoryNameParts name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (name.owner.isNotEmpty) ...<Widget>[
          Text(
            name.owner,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          name.repository,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SubscribersRow extends StatelessWidget {
  const _SubscribersRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.notifications_none_outlined,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Subscribers',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              count.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailFavoriteButton extends StatelessWidget {
  const _DetailFavoriteButton({
    required this.isFavorite,
    required this.enabled,
    required this.onPressed,
  });

  final bool isFavorite;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: IconButton.filledTonal(
        tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
        enableFeedback: false,
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite
              ? const Color(0xFFE3A008)
              : colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
