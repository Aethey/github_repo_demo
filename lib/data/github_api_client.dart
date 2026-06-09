import 'package:github_repository_list_app/config/github_api_config.dart';
import 'package:github_repository_list_app/models/repository_detail.dart';
import 'package:github_repository_list_app/models/repository_search_result.dart';
import 'package:github_repository_list_app/models/repository_summary.dart';
import 'package:github_repository_list_app/network/api_client.dart';

class GithubApiClient {
  GithubApiClient() : _apiClient = ApiClient();

  final ApiClient _apiClient;

  void close() {
    _apiClient.close();
  }

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

    final decoded = await _apiClient.getJsonObject(
      uri,
      headers: GithubApiConfig.headers,
      timeout: GithubApiConfig.requestTimeout,
    );
    final rawItems = decoded['items'];
    final rawTotalCount = decoded['total_count'];

    if (rawItems is! List || rawTotalCount is! num) {
      throw const ApiClientException('Unexpected search response format.');
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
      throw ApiClientException(
        'Failed to parse GitHub search response: ${error.message}',
      );
    } on TypeError {
      throw const ApiClientException('Failed to parse GitHub search response.');
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

    final decoded = await _apiClient.getJsonObject(
      uri,
      headers: GithubApiConfig.headers,
      timeout: GithubApiConfig.requestTimeout,
    );

    try {
      return RepositoryDetail.fromJson(decoded);
    } on FormatException catch (error) {
      throw ApiClientException(
        'Failed to parse repository detail response: ${error.message}',
      );
    } on TypeError {
      throw const ApiClientException(
        'Failed to parse repository detail response.',
      );
    }
  }
}
