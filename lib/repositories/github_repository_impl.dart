import 'package:github_repository_list_app/data/github_api_client.dart';
import 'package:github_repository_list_app/repositories/github_repository.dart';
import 'package:github_repository_list_app/models/repository_detail.dart';
import 'package:github_repository_list_app/models/repository_search_result.dart';

class GithubRepositoryImpl implements GithubRepository {
  GithubRepositoryImpl(this._apiClient);

  final GithubApiClient _apiClient;

  @override
  Future<RepositorySearchResult> searchRepositories({
    required String query,
    int page = 1,
    int perPage = 30,
  }) {
    return _apiClient.searchRepositories(
      query: query,
      page: page,
      perPage: perPage,
    );
  }

  @override
  Future<RepositoryDetail> fetchRepositoryDetail({required String fullName}) {
    return _apiClient.fetchRepositoryDetail(fullName: fullName);
  }
}
