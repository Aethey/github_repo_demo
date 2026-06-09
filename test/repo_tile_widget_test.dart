import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:github_repository_list_app/widgets/repository_tile.dart';

void main() {
  testWidgets(
    'RepositoryTile splits full name into owner and repository text',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _RepositoryTileTestApp(
          child: RepositoryTile(
            fullName:
                'very-long-owner-name-for-layout-testing/'
                'very-long-repository-name-for-layout-testing',
            ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/1?v=4',
            isFavorite: false,
            onTap: () {},
            onFavoritePressed: () {},
          ),
        ),
      );

      expect(
        find.text('very-long-owner-name-for-layout-testing'),
        findsOneWidget,
      );
      expect(
        find.text('very-long-repository-name-for-layout-testing'),
        findsOneWidget,
      );
      expect(
        find.text(
          'very-long-owner-name-for-layout-testing/'
          'very-long-repository-name-for-layout-testing',
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RepositoryTile favorite tap does not trigger row tap', (
    WidgetTester tester,
  ) async {
    var rowTapCount = 0;
    var favoriteTapCount = 0;

    await tester.pumpWidget(
      _RepositoryTileTestApp(
        child: RepositoryTile(
          fullName: 'riverpod/state_notifier',
          ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/2?v=4',
          isFavorite: false,
          onTap: () {
            rowTapCount++;
          },
          onFavoritePressed: () {
            favoriteTapCount++;
          },
        ),
      ),
    );

    await tester.tap(find.byTooltip('Add favorite'));
    await tester.pump();

    expect(favoriteTapCount, 1);
    expect(rowTapCount, 0);

    await tester.tap(find.text('state_notifier'));
    await tester.pump();

    expect(rowTapCount, 1);
  });

  testWidgets('RepositoryTile shows remove favorite action when favorited', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _RepositoryTileTestApp(
        child: RepositoryTile(
          fullName: 'flutter/engine',
          ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/3?v=4',
          isFavorite: true,
          onTap: () {},
          onFavoritePressed: () {},
        ),
      ),
    );

    expect(find.byTooltip('Remove favorite'), findsOneWidget);
    expect(find.byTooltip('Add favorite'), findsNothing);
  });
}

class _RepositoryTileTestApp extends StatelessWidget {
  const _RepositoryTileTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 260, child: child)),
      ),
    );
  }
}
