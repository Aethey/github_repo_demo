import 'package:github_repository_list_app/models/repository_detail.dart';
import 'package:github_repository_list_app/models/repository_summary.dart';
import 'package:github_repository_list_app/utils/json_reader_extension.dart';

class FavoriteRepository {
  const FavoriteRepository({
    required this.id,
    required this.fullName,
    required this.ownerAvatarUrl,
  });

  final int id;
  final String fullName;
  final String ownerAvatarUrl;

  factory FavoriteRepository.fromSummary(RepositorySummary repository) {
    return FavoriteRepository(
      id: repository.id,
      fullName: repository.fullName,
      ownerAvatarUrl: repository.ownerAvatarUrl,
    );
  }

  factory FavoriteRepository.fromDetail(RepositoryDetail repository) {
    return FavoriteRepository(
      id: repository.id,
      fullName: repository.fullName,
      ownerAvatarUrl: repository.ownerAvatarUrl,
    );
  }

  factory FavoriteRepository.fromJson(JsonMap json) {
    return FavoriteRepository(
      id: json.readInt('id'),
      fullName: json.readString('full_name'),
      ownerAvatarUrl: json.readString('owner_avatar_url'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'full_name': fullName,
      'owner_avatar_url': ownerAvatarUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FavoriteRepository &&
            other.id == id &&
            other.fullName == fullName &&
            other.ownerAvatarUrl == ownerAvatarUrl;
  }

  @override
  int get hashCode => Object.hash(id, fullName, ownerAvatarUrl);
}
