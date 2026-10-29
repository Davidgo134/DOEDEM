/// User role in the Marshrutka application.
enum UserRole {
  passenger,
  driver;

  static UserRole? fromString(String? value) {
    if (value == null) return null;
    for (final role in UserRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }
}
