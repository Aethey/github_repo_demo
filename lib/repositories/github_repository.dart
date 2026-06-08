import 'package:github_repository_list_app/models/repository_detail.dart';
import 'package:github_repository_list_app/models/repository_search_result.dart';

abstract interface class GithubRepository {
  Future<RepositorySearchResult> searchRepositories({
    required String query,
    int page,
    int perPage,
  });

  Future<RepositoryDetail> fetchRepositoryDetail({required String fullName});
}
