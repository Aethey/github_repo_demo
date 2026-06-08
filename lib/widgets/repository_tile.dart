import 'package:flutter/material.dart';

import 'package:github_repository_list_app/models/repository_name_parts.dart';

class RepositoryTile extends StatelessWidget {
  const RepositoryTile({
    super.key,
    required this.fullName,
    required this.ownerAvatarUrl,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoritePressed,
    this.favoriteEnabled = true,
  });

  final String fullName;
  final String ownerAvatarUrl;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;
  final bool favoriteEnabled;

  @override
  Widget build(BuildContext context) {
    final name = RepositoryNameParts.fromFullName(fullName);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                RepositoryAvatar(url: ownerAvatarUrl, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (name.owner.isNotEmpty) ...<Widget>[
                        Text(
                          name.owner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        name.repository,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _FavoriteButton(
                  isFavorite: isFavorite,
                  enabled: favoriteEnabled,
                  onPressed: onFavoritePressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
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
      child: IconButton(
        tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
        enableFeedback: false,
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite ? const Color(0xFFE3A008) : colorScheme.outline,
        ),
      ),
    );
  }
}

class RepositoryAvatar extends StatelessWidget {
  const RepositoryAvatar({super.key, required this.url, this.size = 64});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return Container(
            width: size,
            height: size,
            color: colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: SizedBox(
              width: size * 0.42,
              height: size * 0.42,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              Icons.person_outline,
              color: colorScheme.onSurfaceVariant,
              size: size * 0.52,
            ),
          );
        },
      ),
    );
  }
}
