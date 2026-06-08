import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/features/search/search_controller.dart';
import 'package:github_repository_list_app/features/search/search_state.dart';

final searchProvider = NotifierProvider<SearchController, SearchState>(
  SearchController.new,
);
