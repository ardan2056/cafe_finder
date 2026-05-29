import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('demo prefs set and clear', () async {
    SharedPreferences.setMockInitialValues({
      'demo_mode': true,
      'demo_name': 'Tamu',
      'demo_preferences': ['coffee', 'latte'],
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('demo_mode'), true);
    expect(prefs.getString('demo_name'), 'Tamu');
    expect(prefs.getStringList('demo_preferences')?.length, 2);

    // Simulate migration cleanup (the app removes these keys after migrating)
    await prefs.remove('demo_mode');
    await prefs.remove('demo_name');
    await prefs.remove('demo_email');
    await prefs.remove('demo_phone');
    await prefs.remove('demo_role');
    await prefs.remove('demo_photo');
    await prefs.remove('demo_preferences');

    expect(prefs.getBool('demo_mode'), isNull);
    expect(prefs.getString('demo_name'), isNull);
    expect(prefs.getStringList('demo_preferences'), isNull);
  });
}
