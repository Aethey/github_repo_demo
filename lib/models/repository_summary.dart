import 'package:github_repository_list_app/utils/json_reader_extension.dart';

class RepositorySummary {
  const RepositorySummary({
    required this.id,
    required this.fullName,
    required this.ownerAvatarUrl,
  });

  final int id;
  final String fullName;
  final String ownerAvatarUrl;

  factory RepositorySummary.fromJson(JsonMap json) {
    final owner = json.readObject('owner');

    return RepositorySummary(
      id: json.readInt('id'),
      fullName: json.readString('full_name'),
      ownerAvatarUrl: owner.readString('avatar_url'),
    );
  }
}
