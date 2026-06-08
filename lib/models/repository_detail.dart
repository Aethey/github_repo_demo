import 'package:github_repository_list_app/utils/json_reader_extension.dart';

class RepositoryDetail {
  const RepositoryDetail({
    required this.id,
    required this.fullName,
    required this.ownerAvatarUrl,
    required this.subscribersCount,
  });

  final int id;
  final String fullName;
  final String ownerAvatarUrl;
  final int subscribersCount;

  factory RepositoryDetail.fromJson(JsonMap json) {
    final owner = json.readObject('owner');

    return RepositoryDetail(
      id: json.readInt('id'),
      fullName: json.readString('full_name'),
      ownerAvatarUrl: owner.readString('avatar_url'),
      subscribersCount: json.readInt('subscribers_count'),
    );
  }
}
