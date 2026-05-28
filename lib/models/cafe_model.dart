import 'package:cloud_firestore/cloud_firestore.dart';

class CafeModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> facilities;
  final List<String> atmosphere;
  final List<String> categories;
  final double rating;
  final String priceRange;
  final List<String> images;
  final bool isActive;

  CafeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.facilities,
    required this.atmosphere,
    required this.categories,
    required this.rating,
    required this.priceRange,
    required this.images,
    required this.isActive,
  });

  factory CafeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CafeModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      facilities: List<String>.from(data['facilities'] ?? []),
      atmosphere: List<String>.from(data['atmosphere'] ?? []),
      categories: List<String>.from(data['categories'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      priceRange: data['priceRange'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  factory CafeModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CafeModel(
      id: id ?? (map['id'] as String? ?? ''),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      facilities: List<String>.from(map['facilities'] ?? []),
      atmosphere: List<String>.from(map['atmosphere'] ?? []),
      categories: List<String>.from(map['categories'] ?? []),
      rating: (map['rating'] ?? 0).toDouble(),
      priceRange: map['priceRange'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'facilities': facilities,
      'atmosphere': atmosphere,
      'categories': categories,
      'rating': rating,
      'priceRange': priceRange,
      'images': images,
      'isActive': isActive,
    };
  }
}
