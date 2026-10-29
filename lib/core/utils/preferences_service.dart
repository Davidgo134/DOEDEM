import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../models/user_role.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main');
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
});

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  UserRole? getUserRole() {
    final raw = _prefs.getString(AppConstants.prefKeyUserRole);
    return UserRole.fromString(raw);
  }

  Future<void> setUserRole(UserRole? role) async {
    if (role == null) {
      await _prefs.remove(AppConstants.prefKeyUserRole);
    } else {
      await _prefs.setString(AppConstants.prefKeyUserRole, role.name);
    }
  }

  bool hasLocationConsent() {
    return _prefs.getBool(AppConstants.prefKeyLocationConsent) ?? false;
  }

  Future<void> setLocationConsent(bool value) async {
    await _prefs.setBool(AppConstants.prefKeyLocationConsent, value);
  }

  String getOrCreateDeviceId() {
    String? id = _prefs.getString(AppConstants.prefKeyDeviceId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      _prefs.setString(AppConstants.prefKeyDeviceId, id);
    }
    return id;
  }

  bool isBatteryBannerDismissed() {
    return _prefs.getBool(AppConstants.prefKeyBatteryBannerDismissed) ?? false;
  }

  Future<void> setBatteryBannerDismissed(bool value) async {
    await _prefs.setBool(AppConstants.prefKeyBatteryBannerDismissed, value);
  }
}
