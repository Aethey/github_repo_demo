import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:github_repository_list_app/models/favorite_repository.dart';
import 'package:github_repository_list_app/features/favorites/favorite_provider.dart';
import 'package:github_repository_list_app/providers/shared_preferences_provider.dart';

void main() {
  test('FavoriteController adds and removes repositories', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );
    addTearDown(container.dispose);

    const repository = FavoriteRepository(
      id: 1,
      fullName: 'flutter/flutter',
      ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/14101776?v=4',
    );

    expect(
      (await container.read(favoriteProvider.future)).repositories,
      isEmpty,
    );

    await container.read(favoriteProvider.notifier).add(repository);
    expect(
      container.read(favoriteProvider).requireValue.repositories,
      contains(repository),
    );

    await container.read(favoriteProvider.notifier).remove(repository.id);
    expect(container.read(favoriteProvider).requireValue.repositories, isEmpty);
  });

  test('FavoriteController ignores corrupted stored entries', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'favorite_repositories': <String>[
        'not-json',
        '{"id":"bad","full_name":"broken/repository","owner_avatar_url":"https://example.com/avatar.png"}',
        '{"id":7,"full_name":"valid/repository","owner_avatar_url":"https://example.com/avatar.png"}',
      ],
    });
    final sharedPreferences = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
    );
    addTearDown(container.dispose);

    final repositories = (await container.read(
      favoriteProvider.future,
    )).repositories;

    expect(repositories, hasLength(1));
    expect(repositories.single.id, 7);
    expect(repositories.single.fullName, 'valid/repository');
  });
}
