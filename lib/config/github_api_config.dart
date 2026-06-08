class GithubApiConfig {
  const GithubApiConfig._();

  static const String scheme = 'https';
  static const String host = 'api.github.com';
  static const String searchRepositoriesPath = '/search/repositories';
  static const String repositoryDetailPathSegment = 'repos';
  static const Duration requestTimeout = Duration(seconds: 15);

  static const Map<String, String> headers = <String, String>{
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };
}
