import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/features/search/search_history_controller.dart';
import 'package:github_repository_list_app/features/search/search_history_state.dart';

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryController, SearchHistoryState>(
      SearchHistoryController.new,
    );
