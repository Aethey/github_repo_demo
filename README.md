# github_repository_list_app

Production-quality Flutter interview assignment that searches public GitHub
repositories, shows repository details, and stores local favorites.

## Overview

The app has two bottom navigation tabs:

- Search: submit a keyword to search GitHub repositories, browse persisted search history, paginate results, favorite/unfavorite, and open detail.
- Star: list locally favorited repositories, remove favorites, and open detail.

Repository Detail is pushed on top of either tab and is not part of the bottom
navigation. It fetches fresh detail data from GitHub and shows `full_name`,
`owner.avatar_url`, `subscribers_count`, and the synchronized favorite action.

## Architecture

The code uses a simple MVVM-style Riverpod structure with Repository interfaces.
It avoids a full multi-layer Clean Architecture tree because the app has a small
feature surface.

- `lib/models`: shared immutable app models used by multiple screens.
- `lib/data`: concrete GitHub API and local `shared_preferences` storage classes.
- `lib/repositories`: Repository interfaces and implementations that isolate data access.
- `lib/providers`: app-wide dependency providers such as SharedPreferences, HTTP, storage, and repositories.
- `lib/config`: app-wide configuration values.
- `lib/features/search`: search screen, search state, search controller, and search-history state/controller.
- `lib/features/favorites`: favorite list screen, favorite state, controller, and provider.
- `lib/features/detail`: repository detail screen, detail state, controller, and provider.
- `lib/widgets`: shared UI widgets.
- `lib/utils`: shared parsing helpers.

Feature controllers depend on Repository interfaces through Riverpod providers,
not directly on the GitHub API client or SharedPreferences storage classes.
Repository implementations adapt those interfaces to GitHub REST API and local
storage.

Search is intentionally submitted by the keyboard search action or by selecting
a recent search record. Typing in the field does not call the GitHub API.

## Package Usage

- `http`: calls GitHub REST endpoints.
- `shared_preferences`: persists local favorite repositories and recent search keywords.
- `flutter_riverpod`: single source of truth for search, detail, and favorite state.

No GitHub authorization header is used, and no GitHub Star API calls are made.

## GitHub API

Search uses:

```text
GET https://api.github.com/search/repositories?q={query}&page={page}&per_page=30
```

Detail uses:

```text
GET https://api.github.com/repos/{owner}/{repo}
```

The API layer handles network timeouts, non-2xx responses, malformed JSON, and
unexpected response shapes by surfacing readable error states in the UI.

## State Synchronization

Favorites are managed by `favoriteProvider`, an `AsyncNotifier` backed by
`shared_preferences`. Search, Star, and Detail screens all watch the same
provider, so changes propagate immediately:

- Favorite from Search updates Star.
- Favorite from Detail updates Search and Star.
- Unfavorite from Star updates Detail and Search.

Only these fields are persisted locally:

- `id`
- `full_name`
- `owner.avatar_url`

## Build Instructions

```sh
flutter pub get
flutter run
flutter test
```

The project supports Android and iOS with Flutter 3.41.x or higher.
