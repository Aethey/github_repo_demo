import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:github_repository_list_app/features/favorites/favorite_controller.dart';
import 'package:github_repository_list_app/features/favorites/favorite_state.dart';

final favoriteProvider =
    AsyncNotifierProvider<FavoriteController, FavoriteState>(
      FavoriteController.new,
    );
