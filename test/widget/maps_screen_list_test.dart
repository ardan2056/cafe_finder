import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_finder/features/maps/maps_screen.dart';
import 'package:cafe_finder/models/cafe_model.dart';
import 'package:cafe_finder/services/cafe_service.dart';

class FakeCafeService extends CafeService {
  final StreamController<List<CafeModel>> _ctrl = StreamController.broadcast();
  @override
  Stream<List<CafeModel>> getCafes() => _ctrl.stream;
  void add(List<CafeModel> data) => _ctrl.add(data);
  void close() => _ctrl.close();
}

void main() {
  testWidgets('MapsScreen renders cafe list when service provides data', (tester) async {
    final fake = FakeCafeService();

    await tester.pumpWidget(MaterialApp(home: MapsScreen(cafeService: fake)));

    // Provide one cafe
    final cafe = CafeModel(
      id: '1',
      name: 'Test Cafe',
      description: 'desc',
      address: 'Addr 1',
      latitude: -1.0,
      longitude: 116.0,
      facilities: [],
      atmosphere: [],
      categories: [],
      rating: 4.0,
      priceRange: '',
      images: [],
      isActive: true,
    );

    fake.add([cafe]);

    await tester.pumpAndSettle();

    expect(find.text('Test Cafe'), findsOneWidget);
    expect(find.text('Addr 1'), findsOneWidget);

    // Tap the list tile to ensure it responds
    await tester.tap(find.text('Test Cafe'));
    await tester.pumpAndSettle();

    fake.close();
  });
}
