class RepositoryNameParts {
  const RepositoryNameParts({required this.owner, required this.repository});

  factory RepositoryNameParts.fromFullName(String fullName) {
    final slashIndex = fullName.indexOf('/');
    if (slashIndex <= 0 || slashIndex == fullName.length - 1) {
      return RepositoryNameParts(owner: '', repository: fullName);
    }

    return RepositoryNameParts(
      owner: fullName.substring(0, slashIndex),
      repository: fullName.substring(slashIndex + 1),
    );
  }

  final String owner;
  final String repository;
}
