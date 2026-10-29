import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_role.dart';
import '../../core/utils/preferences_service.dart';

final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole?>(UserRoleNotifier.new);

class UserRoleNotifier extends Notifier<UserRole?> {
  @override
  UserRole? build() {
    final prefsService = ref.watch(preferencesServiceProvider);
    return prefsService.getUserRole();
  }

  Future<void> selectRole(UserRole role) async {
    final prefsService = ref.read(preferencesServiceProvider);
    await prefsService.setUserRole(role);
    state = role;
  }

  Future<void> clearRole() async {
    final prefsService = ref.read(preferencesServiceProvider);
    await prefsService.setUserRole(null);
    state = null;
  }
}
