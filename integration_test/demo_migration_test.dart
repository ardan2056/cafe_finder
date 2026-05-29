// Runs only when USE_FIREBASE_EMULATOR=1 is set in the environment.
import 'dart:io';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cafe_finder/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final useEmu = Platform.environment['USE_FIREBASE_EMULATOR'] == '1';

  testWidgets('guest -> register migration (emulator)', (tester) async {
    if (!useEmu) {
      // Skip if emulators aren't enabled; prevents accidental runs against prod.
      return;
    }

    // Start app
    app.main();
    await tester.pumpAndSettle();

    // Tap "Masuk sebagai Tamu" button. Widget text may vary by localization.
    final guestBtn = find.text('Masuk sebagai Tamu');
    expect(guestBtn, findsOneWidget);
    await tester.tap(guestBtn);
    await tester.pumpAndSettle();

    // Navigate to Profile and press upgrade/register.
    final profileNav = find.byIcon(Icons.person_rounded);
    expect(profileNav, findsOneWidget);
    await tester.tap(profileNav);
    await tester.pumpAndSettle();

    // Find and tap 'Buat Akun' or 'Upgrade' button to create an account
    final createBtn = find.text('Buat Akun');
    expect(createBtn, findsWidgets);
    await tester.tap(createBtn.first);
    await tester.pumpAndSettle();

    // Fill registration fields (best-effort selectors)
    await tester.enterText(find.byType(TextField).at(0), 'E2E Tester');
    await tester.enterText(find.byType(TextField).at(1), 'e2e@example.test');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), '+621234567890');
    await tester.pumpAndSettle();

    // Submit registration
    final registerBtn = find.text('Daftar');
    expect(registerBtn, findsWidgets);
    await tester.tap(registerBtn.first);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // At this point the app should have created a users/{uid} doc in emulator Firestore.
    // We do not inspect emulator here; use `scripts/inspect_emulator_users.js` to validate.
  }, timeout: const Timeout(Duration(minutes: 3)));
}
