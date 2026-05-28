import 'package:flutter/foundation.dart';

import '../models/cafe.dart';

class CafeProvider extends ChangeNotifier {
  final List<Cafe> _cafes = sampleCafes();
  final Set<String> _favoriteIds = {};
  String _searchQuery = '';

  List<Cafe> get cafes {
    if (_searchQuery.isEmpty) {
      return List<Cafe>.unmodifiable(_cafes);
    }

    final query = _searchQuery.toLowerCase();
    return _cafes
        .where((cafe) =>
            cafe.name.toLowerCase().contains(query) ||
            cafe.location.toLowerCase().contains(query) ||
            cafe.description.toLowerCase().contains(query))
        .toList(growable: false);
  }

  List<Cafe> get favorites =>
      _cafes.where((cafe) => _favoriteIds.contains(cafe.id)).toList(growable: false);

  String get searchQuery => _searchQuery;

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool isFavorite(String cafeId) => _favoriteIds.contains(cafeId);

  void toggleFavorite(String cafeId) {
    if (_favoriteIds.contains(cafeId)) {
      _favoriteIds.remove(cafeId);
    } else {
      _favoriteIds.add(cafeId);
    }
    notifyListeners();
  }

  Cafe? getCafeById(String id) {
    for (final cafe in _cafes) {
      if (cafe.id == id) {
        return cafe;
      }
    }
    return null;
  }
}
