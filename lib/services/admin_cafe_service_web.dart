import '../models/cafe_model.dart';
import 'cafe_service_web.dart';

class AdminCafeService {
  Future<void> seedDefaults() async {
    await DemoCafeStore.instance.seedDefaults();
  }

  Future<void> addCafe({
    required String name,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> facilities,
    required List<String> atmosphere,
    required List<String> categories,
    required String priceRange,
    List<String>? images,
  }) async {
    final id = 'demo-${DateTime.now().millisecondsSinceEpoch}';
    final cafe = CafeModel(
      id: id,
      name: name,
      description: description,
      address: address,
      latitude: latitude,
      longitude: longitude,
      facilities: facilities,
      atmosphere: atmosphere,
      categories: categories,
      rating: 0.0,
      priceRange: priceRange,
      images: images ?? [],
      isActive: true,
    );

    await DemoCafeStore.instance.addCafe(cafe);
  }

  Future<void> updateCafe({
    required String cafeId,
    required Map<String, dynamic> data,
  }) async {
    final current = await DemoCafeStore.instance.readAll();
    final updated = current.map((c) {
      if (c.id == cafeId) {
        final map = c.toMap();
        map.addAll(data);
        return CafeModel.fromMap(map, id: cafeId);
      }
      return c;
    }).toList();
    await DemoCafeStore.instance.replaceAll(updated);
  }

  Future<void> setCafeActive({
    required String cafeId,
    required bool isActive,
  }) async {
    final current = await DemoCafeStore.instance.readAll();
    final updated = current
        .map((c) => c.id == cafeId
            ? CafeModel.fromMap({...c.toMap(), 'isActive': isActive}, id: c.id)
            : c)
        .toList();
    await DemoCafeStore.instance.replaceAll(updated);
  }
}
