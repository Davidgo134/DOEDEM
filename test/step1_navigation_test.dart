import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marshrutka/app/strings.dart';
import 'package:marshrutka/core/models/user_role.dart';
import 'package:marshrutka/core/utils/preferences_service.dart';
import 'package:marshrutka/features/passenger/passenger_screen.dart';
import 'package:marshrutka/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('First launch displays role selection screen', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MarshrutkaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.roleSelectTitle), findsOneWidget);
    expect(find.text(AppStrings.rolePassenger), findsOneWidget);
    expect(find.text(AppStrings.roleDriver), findsOneWidget);
  });

  testWidgets('Selecting Passenger role navigates to Passenger screen and persists role', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MarshrutkaApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.rolePassenger));
    await tester.pumpAndSettle();

    // Verify persisted
    final prefsService = PreferencesService(prefs);
    expect(prefsService.getUserRole(), UserRole.passenger);
    expect(find.byType(PassengerScreen), findsOneWidget);
  });

  testWidgets('Selecting Driver role navigates to Driver screen and persists role', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MarshrutkaApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.roleDriver));
    await tester.pumpAndSettle();

    // Verify persisted
    final prefsService = PreferencesService(prefs);
    expect(prefsService.getUserRole(), UserRole.driver);
    expect(find.text(AppStrings.driverShiftStart), findsOneWidget);
  });
}
