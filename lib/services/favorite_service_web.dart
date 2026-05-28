// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const _storageKey = 'demo_favorites';

  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;

  // in-memory cache and broadcast stream for favorites
  List<String> _cache = [];
  late final StreamController<List<String>> _broadcast;

  FavoriteService._internal() {
    _broadcast = StreamController<List<String>>.broadcast(
      onListen: () {
        // emit current cache immediately to new listeners
        _broadcast.add(_cache);
      },
    );

    // initialize cache from storage
    _initFromStorage();
  }

  String get userId => 'web_demo_user';

  Stream<List<String>> favoriteIds() => _broadcast.stream;

  Stream<bool> isFavorite(String cafeId) {
    return _broadcast.stream.map((ids) => ids.contains(cafeId)).distinct();
  }

  Future<void> _initFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cache = prefs.getStringList(_storageKey) ?? <String>[];
    } catch (_) {
      try {
        final raw = html.window.localStorage[_storageKey];
        if (raw != null) {
          _cache = List<String>.from(jsonDecode(raw) as List<dynamic>);
        } else {
          _cache = <String>[];
        }
      } catch (_) {
        _cache = <String>[];
      }
    }

    if (!_broadcast.isClosed) _broadcast.add(_cache);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _cache);
    } catch (_) {
      try {
        html.window.localStorage[_storageKey] = jsonEncode(_cache);
      } catch (_) {}
    }
  }

  Future<void> addFavorite(String cafeId) async {
    if (!_cache.contains(cafeId)) {
      _cache = [..._cache, cafeId];
      await _persist();
      if (!_broadcast.isClosed) _broadcast.add(_cache);
    }
  }

  Future<void> removeFavorite(String cafeId) async {
    if (_cache.contains(cafeId)) {
      _cache = _cache.where((id) => id != cafeId).toList();
      await _persist();
      if (!_broadcast.isClosed) _broadcast.add(_cache);
    }
  }
}
