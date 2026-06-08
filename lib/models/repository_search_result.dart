import 'package:github_repository_list_app/models/repository_summary.dart';

class RepositorySearchResult {
  const RepositorySearchResult({required this.items, required this.totalCount});

  final List<RepositorySummary> items;
  final int totalCount;
}
