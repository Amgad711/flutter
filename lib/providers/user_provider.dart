import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final userProvider = StreamProvider.family<UserModel, String>((ref, userId) {
  return ref.watch(userServiceProvider).watchUser(userId);
});

final userSearchProvider = StateNotifierProvider<UserSearchNotifier, AsyncValue<List<UserModel>>>(
  (ref) => UserSearchNotifier(ref.watch(userServiceProvider)),
);

class UserSearchNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final UserService _userService;

  UserSearchNotifier(this._userService) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final results = await _userService.searchUsers(query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data([]);
}
