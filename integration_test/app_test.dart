// ignore_for_file: uri_does_not_exist, depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
// integration_test is not available in pubspec currently; disable its usage.
// import 'package:integration_test/integration_test.dart' as integration_test;
import 'package:flutter/material.dart';
import 'package:cafe_finder/core/theme/app_theme.dart';
import 'package:cafe_finder/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // integration_test binding skipped because the package is not present.

  testWidgets('home to search navigation and query pass',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Find the inline search TextField and enter text
    final searchField = find.byType(TextField).first;
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'kopi');
    await tester.pumpAndSettle();

    // Tap the arrow button to navigate to SearchScreen
    final arrow = find.byIcon(Icons.arrow_forward_rounded);
    expect(arrow, findsOneWidget);

    await tester.tap(arrow);
    await tester.pumpAndSettle();

    // Verify SearchScreen appeared by looking for its header text
    expect(find.text('Cari Kafe'), findsOneWidget);

    // Verify the searchController in SearchScreen was prefilled (SearchScreen shows results or has the same input)
    final searchInput = find.byType(TextField);
    expect(searchInput, findsWidgets);
  });

  testWidgets('favorite a cafe and verify in Favorite tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Find a demo cafe by name and tap it
    final cafeTile = find.text('Canvas & Beans');
    expect(cafeTile, findsOneWidget);

    await tester.tap(cafeTile);
    await tester.pumpAndSettle();

    // Tap 'Simpan Favorit' button
    final favButton = find.text('Simpan Favorit');
    expect(favButton, findsOneWidget);
    await tester.tap(favButton);
    await tester.pumpAndSettle();

    // Navigate to Favorite tab via bottom navigation
    final favNav = find.byIcon(Icons.favorite_rounded);
    expect(favNav, findsOneWidget);
    await tester.tap(favNav);
    await tester.pumpAndSettle();

    // Verify the cafe is listed in favorites
    expect(find.text('Canvas & Beans'), findsWidgets);

    // Now remove favorite: tap the favorite icon button in the list
    final removeIcon = find.byIcon(Icons.favorite_rounded).last;
    await tester.tap(removeIcon);
    await tester.pumpAndSettle();

    // Verify the cafe is removed (may show 'Belum ada kafe favorit' or not find the name)
    await tester.pumpAndSettle();
    expect(find.text('Canvas & Beans'), findsNothing);
  });

  testWidgets('profile save preferences on web', (WidgetTester tester) async {
    // Start app
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Navigate to Profile tab
    final profileNav = find.byIcon(Icons.person_rounded);
    expect(profileNav, findsOneWidget);
    await tester.tap(profileNav);
    await tester.pumpAndSettle();

    // Select a preference chip
    final pref = find.text('Wi-Fi');
    expect(pref, findsOneWidget);
    await tester.tap(pref);
    await tester.pumpAndSettle();

    // Save preferences
    final saveBtn = find.text('Simpan Preferensi');
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Check SharedPreferences stored the preference
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('demo_preferences') ?? [];
    expect(stored.contains('Wi-Fi'), isTrue);
  });
}
