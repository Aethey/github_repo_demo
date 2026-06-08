import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:github_repository_list_app/features/detail/detail_screen.dart';
import 'package:github_repository_list_app/features/search/search_screen.dart';
import 'package:github_repository_list_app/models/repository_detail.dart';
import 'package:github_repository_list_app/models/repository_search_result.dart';
import 'package:github_repository_list_app/models/repository_summary.dart';
import 'package:github_repository_list_app/providers/shared_preferences_provider.dart';
import 'package:github_repository_list_app/providers/repository_providers.dart';
import 'package:github_repository_list_app/repositories/github_repository.dart';

void main() {
  testWidgets('Search screen shows home state when search text is empty', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const MaterialApp(home: Scaffold(body: SearchScreen())),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('repository-search-field')),
      findsOneWidget,
    );
    expect(find.text('Search GitHub repositories'), findsOneWidget);
    expect(
      find.text('Enter a keyword to find public repositories on GitHub.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('repository-search-field')),
      'flutter',
    );
    await tester.pump();

    expect(find.text('Search GitHub repositories'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'Search history is shown only while the search field is focused',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'search_history': <String>['flutter'],
      });
      final sharedPreferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const MaterialApp(home: Scaffold(body: SearchScreen())),
        ),
      );
      await tester.pump();

      final searchField = find.byKey(
        const ValueKey<String>('repository-search-field'),
      );

      expect(find.text('flutter'), findsNothing);

      await tester.tap(searchField);
      await tester.pumpAndSettle();

      expect(find.text('flutter'), findsOneWidget);

      await tester.tapAt(const Offset(20, 400));
      await tester.pumpAndSettle();

      expect(find.text('flutter'), findsNothing);
    },
  );

  testWidgets('Search error can be retried from the error view', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();
    final githubRepository = _FailThenSucceedGithubRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          githubRepositoryProvider.overrideWithValue(githubRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: SearchScreen())),
      ),
    );

    final searchField = find.byKey(
      const ValueKey<String>('repository-search-field'),
    );

    await tester.tap(searchField);
    await tester.enterText(searchField, 'state');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Search failed'), findsOneWidget);
    expect(
      find.textContaining('Could not load results for "state".'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Search failed'), findsNothing);
    expect(find.text('riverpod'), findsOneWidget);
    expect(find.text('state_notifier'), findsOneWidget);
    expect(githubRepository.searchCallCount, 2);
  });

  testWidgets('Detail page load error can be retried from the error view', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();
    final githubRepository = _FailThenSucceedGithubRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          githubRepositoryProvider.overrideWithValue(githubRepository),
        ],
        child: const MaterialApp(
          home: DetailScreen(fullName: 'flutter/engine'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load repository'), findsOneWidget);
    expect(
      find.textContaining('Repository detail unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load repository'), findsNothing);
    expect(find.text('flutter'), findsOneWidget);
    expect(find.text('engine'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
    expect(githubRepository.detailCallCount, 2);
  });
}

class _FailThenSucceedGithubRepository implements GithubRepository {
  int searchCallCount = 0;
  int detailCallCount = 0;

  @override
  Future<RepositorySearchResult> searchRepositories({
    required String query,
    int page = 1,
    int perPage = 30,
  }) async {
    searchCallCount++;
    if (searchCallCount == 1) {
      throw Exception('Network unavailable.');
    }

    return const RepositorySearchResult(
      items: <RepositorySummary>[
        RepositorySummary(
          id: 1,
          fullName: 'riverpod/state_notifier',
          ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/1?v=4',
        ),
      ],
      totalCount: 1,
    );
  }

  @override
  Future<RepositoryDetail> fetchRepositoryDetail({
    required String fullName,
  }) async {
    detailCallCount++;
    if (detailCallCount == 1) {
      throw Exception('Repository detail unavailable.');
    }

    return RepositoryDetail(
      id: 1,
      fullName: fullName,
      ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/1?v=4',
      subscribersCount: 123,
    );
  }
}
