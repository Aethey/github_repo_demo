import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:github_repository_list_app/config/app_config.dart';
import 'package:github_repository_list_app/features/search/search_history_provider.dart';
import 'package:github_repository_list_app/providers/shared_preferences_provider.dart';

void main() {
  test(
    'SearchHistoryController keeps only the configured latest records',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final sharedPreferences = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
      );
      addTearDown(container.dispose);

      for (var index = 0; index < AppConfig.searchHistoryLimit + 2; index++) {
        await container
            .read(searchHistoryProvider.notifier)
            .add('query $index');
      }

      final keywords = container
          .read(searchHistoryProvider)
          .requireValue
          .keywords;
      final storedKeywords =
          sharedPreferences.getStringList('search_history') ?? const <String>[];

      expect(keywords, hasLength(AppConfig.searchHistoryLimit));
      expect(storedKeywords, hasLength(AppConfig.searchHistoryLimit));
      expect(keywords.first, 'query ${AppConfig.searchHistoryLimit + 1}');
      expect(storedKeywords.first, 'query ${AppConfig.searchHistoryLimit + 1}');
      expect(keywords.last, 'query 2');
      expect(storedKeywords.last, 'query 2');
    },
  );
}
