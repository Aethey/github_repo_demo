# github_repository_list_app

Flutter application for searching public GitHub repositories, viewing repository
details, and managing local favorites.

## Requirements

- Flutter 3.41.x or higher
- Android and iOS support
- No GitHub Authorization header

## Packages

- `http`: GitHub REST API requests
- `shared_preferences`: local favorites and search history persistence
- `flutter_riverpod`: state management and dependency injection

No additional third-party packages are used.

## How To Run

```sh
flutter pub get
flutter run
flutter test
```

## Features

- Bottom navigation with Search and Star tabs
- Repository search by submitted keyword
- Search home, loading, empty, and error states
- Search history stored in `shared_preferences`
- Infinite scroll using GitHub Search API pagination
- Pull-to-refresh for search results
- Repository detail screen
- Local favorite add/remove without GitHub Star API
- Favorite state synchronization across Search, Detail, and Star screens
- Favorites persist across app restart

## GitHub REST API

Repository Search API:

```text
GET https://api.github.com/search/repositories?q={query}&page={page}&per_page=30
```

Repository Detail API:

```text
GET https://api.github.com/repos/{owner}/{repo}
```

The app handles non-2xx responses, timeouts, network errors, JSON decode errors,
and unexpected response shapes.

## Project Structure

```text
lib/
  main.dart
  app.dart
  main_screen.dart
  config/
  models/
  network/
  data/
  repositories/
  providers/
  features/
    search/
    favorites/
    detail/
  widgets/
  utils/
```

Main responsibilities:

- `config`: app and GitHub API constants
- `models`: shared immutable models
- `network`: low-level HTTP/JSON request utility
- `data`: GitHub API client and local storage classes
- `repositories`: repository interfaces and implementations
- `providers`: Riverpod dependency providers
- `features/search`: search UI, state, controllers, and search history
- `features/favorites`: favorite list UI, state, and controller
- `features/detail`: detail UI, state, and controller
- `widgets`: shared UI components
- `utils`: shared helpers

## Key Implementation Points

- Search requests are triggered by the keyboard search action or by selecting a search history item, not on every text change.
- Search history keeps the latest configured number of records.
- Search pagination requests one page at a time and prevents duplicate next-page requests.
- Favorites are stored locally with only:
  - `id`
  - `full_name`
  - `owner.avatar_url`
- `favoriteProvider` is the single source of truth for favorite state.
- `detailProvider` is `autoDispose` because detail screens are pushed pages.

## `full_name` Display

The task requires displaying `full_name`.

GitHub repository `full_name` has this format:

```text
owner/repository
```

The app keeps `full_name` as the source value and splits it by `/` only for UI
display:

```text
owner
repository
```

This is used in repository list items and the detail screen.

Reason:

- It satisfies the task requirement to use `full_name`.
- It avoids adding unnecessary display fields.
- It reduces the chance of long `owner/repository` text overflowing the screen.
- It improves readability and visual hierarchy.

## Tests

The project includes unit and widget tests for:

- favorite add/remove logic
- low-level API client success and error handling
- search history limit
- search pagination and stale-response handling
- repository tile display and tap behavior
- search home state
- search history focus behavior
- search error retry
- detail error retry
