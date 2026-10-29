import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/user_role.dart';
import '../features/driver/driver_screen.dart';
import '../features/passenger/passenger_screen.dart';
import '../features/role_select/role_controller.dart';
import '../features/role_select/role_select_screen.dart';

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);

    switch (role) {
      case null:
        return const RoleSelectScreen();
      case UserRole.driver:
        return const DriverScreen();
      case UserRole.passenger:
        return const PassengerScreen();
    }
  }
}
