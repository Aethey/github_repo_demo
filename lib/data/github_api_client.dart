import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:github_repository_list_app/config/github_api_config.dart';
import 'package:github_repository_list_app/models/repository_detail.dart';
import 'package:github_repository_list_app/models/repository_search_result.dart';
import 'package:github_repository_list_app/models/repository_summary.dart';

class GithubApiClient {
  GithubApiClient(this._client);

  final http.Client _client;

  Future<RepositorySearchResult> searchRepositories({
    required String query,
    int page = 1,
    int perPage = 30,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const RepositorySearchResult(
        items: <RepositorySummary>[],
        totalCount: 0,
      );
    }

    final uri = Uri.https(
      GithubApiConfig.host,
      GithubApiConfig.searchRepositoriesPath,
      <String, String>{
        'q': trimmedQuery,
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    final response = await _get(uri);
    final decoded = _decodeObject(response.body);
    final rawItems = decoded['items'];
    final rawTotalCount = decoded['total_count'];

    if (rawItems is! List || rawTotalCount is! num) {
      throw const GithubApiException('Unexpected search response format.');
    }

    try {
      final items = rawItems
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid repository item.');
            }
            return RepositorySummary.fromJson(item);
          })
          .toList(growable: false);

      return RepositorySearchResult(
        items: items,
        totalCount: rawTotalCount.toInt(),
      );
    } on FormatException catch (error) {
      throw GithubApiException(
        'Failed to parse GitHub search response: ${error.message}',
      );
    } on TypeError {
      throw const GithubApiException('Failed to parse GitHub search response.');
    }
  }

  Future<RepositoryDetail> fetchRepositoryDetail({
    required String fullName,
  }) async {
    final parts = fullName.split('/');
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
      throw ArgumentError.value(
        fullName,
        'fullName',
        'Expected "owner/repository".',
      );
    }

    final uri = Uri(
      scheme: GithubApiConfig.scheme,
      host: GithubApiConfig.host,
      pathSegments: <String>[
        GithubApiConfig.repositoryDetailPathSegment,
        parts[0],
        parts[1],
      ],
    );

    final response = await _get(uri);
    final decoded = _decodeObject(response.body);

    try {
      return RepositoryDetail.fromJson(decoded);
    } on FormatException catch (error) {
      throw GithubApiException(
        'Failed to parse repository detail response: ${error.message}',
      );
    } on TypeError {
      throw const GithubApiException(
        'Failed to parse repository detail response.',
      );
    }
  }

  Future<http.Response> _get(Uri uri) async {
    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: GithubApiConfig.headers)
          .timeout(GithubApiConfig.requestTimeout);
    } on TimeoutException {
      throw const GithubApiException('GitHub request timed out.');
    } on http.ClientException catch (error) {
      throw GithubApiException('Network error: ${error.message}');
    } on Object {
      throw const GithubApiException('Network error while contacting GitHub.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GithubApiException(
        _messageForNonSuccess(response),
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const FormatException('Response root is not an object.');
    } on FormatException catch (error) {
      throw GithubApiException(
        'Failed to decode GitHub response: ${error.message}',
      );
    }
  }

  String _messageForNonSuccess(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return 'GitHub API error (${response.statusCode}): $message';
        }
      }
    } on FormatException {
      // Fall back to a generic status message below.
    }

    return 'GitHub API error (${response.statusCode}).';
  }
}

class GithubApiException implements Exception {
  const GithubApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
