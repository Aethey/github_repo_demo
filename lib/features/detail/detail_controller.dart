import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/providers/repository_providers.dart';
import 'package:github_repository_list_app/features/detail/detail_state.dart';

class DetailController extends AsyncNotifier<DetailState> {
  DetailController(this.fullName);

  final String fullName;

  @override
  FutureOr<DetailState> build() async {
    final githubRepository = ref.watch(githubRepositoryProvider);
    final repository = await githubRepository.fetchRepositoryDetail(
      fullName: fullName,
    );
    return DetailState(repository: repository);
  }
}
