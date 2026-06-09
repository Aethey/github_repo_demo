import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/features/detail/detail_state.dart';
import 'package:github_repository_list_app/features/detail/detail_controller.dart';

final detailProvider = AsyncNotifierProvider.family
    .autoDispose<DetailController, DetailState, String>(
      DetailController.new,
      retry: (retryCount, error) => null,
    );
