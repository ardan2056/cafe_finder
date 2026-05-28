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
}

void main() {
  testWidgets('MapsScreen shows list header with no cafes', (tester) async {
    final fake = FakeCafeService();

    await tester.pumpWidget(MaterialApp(home: MapsScreen(cafeService: fake)));

    // Wait for the widget tree to build
    await tester.pumpAndSettle();

    expect(find.text('Daftar Cafe Terdekat'), findsOneWidget);
  });
}
