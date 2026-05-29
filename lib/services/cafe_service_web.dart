// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'html_stub.dart'
  if (dart.library.html) 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cafe_model.dart';

class CafeService {
  final DemoCafeStore _store = DemoCafeStore.instance;

  Stream<List<CafeModel>> getCafes() => _store.stream;
}

class DemoCafeStore {
  static final DemoCafeStore instance = DemoCafeStore._internal();

  // Broadcast controller that will send the latest list to each new listener
  late final StreamController<List<CafeModel>> _broadcast;
  // in-memory cache of cafes to serve immediately
  List<CafeModel> _cache = [];

  Stream<List<CafeModel>> get stream => _broadcast.stream;

  static const _prefsKey = 'demo_cafes_v1';

  Future<void> _ensureInitial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_prefsKey)) {
        final initial = _defaultCafes.map((c) => c.toMap()).toList();
        await prefs.setString(_prefsKey, jsonEncode(initial));
      }
    } catch (e) {
      // fallback to localStorage
      if (html.window.localStorage[_prefsKey] == null) {
        html.window.localStorage[_prefsKey] =
            jsonEncode(_defaultCafes.map((c) => c.toMap()).toList());
      }
    }
  }

  Future<List<CafeModel>> _readAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      final mapped = list
          .map((e) => CafeModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _cache = mapped;
      return mapped;
    } catch (e) {
      final raw = html.window.localStorage[_prefsKey];
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      final mapped = list
          .map((e) => CafeModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _cache = mapped;
      return mapped;
    }
  }

  /// Public read method for other modules
  Future<List<CafeModel>> readAll() => _readAll();

  Future<void> addCafe(CafeModel cafe) async {
    await _ensureInitial();
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _readAll();
      final newList = [...current, cafe];
      await prefs.setString(
          _prefsKey, jsonEncode(newList.map((c) => c.toMap()).toList()));
      _cache = newList;
      _broadcast.add(_cache);
    } catch (e) {
      final current = await _readAll();
      final newList = [...current, cafe];
      html.window.localStorage[_prefsKey] =
          jsonEncode(newList.map((c) => c.toMap()).toList());
      _cache = newList;
      _broadcast.add(_cache);
    }
  }

  Future<void> replaceAll(List<CafeModel> cafes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefsKey, jsonEncode(cafes.map((c) => c.toMap()).toList()));
      _cache = cafes;
      _broadcast.add(_cache);
    } catch (e) {
      html.window.localStorage[_prefsKey] =
          jsonEncode(cafes.map((c) => c.toMap()).toList());
      _cache = cafes;
      _broadcast.add(_cache);
    }
  }

  DemoCafeStore._internal() {
    // initialize broadcast controller after instance is created so we can
    // safely reference instance members inside the onListen callback.
    _broadcast = StreamController<List<CafeModel>>.broadcast(
      onListen: () async {
        try {
          final current = await _readAll();
          if (!_broadcast.isClosed) _broadcast.add(current);
        } catch (_) {
          if (!_broadcast.isClosed) _broadcast.add(<CafeModel>[]);
        }
      },
    );

    // ensure initial prefs/localStorage are seeded and emit initial list
    _ensureInitial().then((_) async {
      final list = await _readAll();
      _cache = list;
      if (!_broadcast.isClosed) _broadcast.add(_cache);
    });
  }

  /// Replace current list with default sample cafes
  Future<void> seedDefaults() async {
    await replaceAll(_defaultCafes);
  }
}

final List<CafeModel> _defaultCafes = [
  CafeModel(
    id: 'demo-1',
    name: 'Navy Brew Space',
    description: 'Cafe nyaman untuk kerja fokus dan meeting santai.',
    address: 'Jl. Merdeka No. 12, Balikpapan',
    latitude: -1.2379,
    longitude: 116.8529,
    facilities: ['Wi-Fi', 'Colokan', 'Meeting Room'],
    atmosphere: ['Tenang', 'Kerja'],
    categories: ['Kerja', 'Meeting'],
    rating: 4.8,
    priceRange: 'Rp25k - Rp50k',
    images: const [],
    isActive: true,
  ),
  CafeModel(
    id: 'demo-2',
    name: 'Sunset Corner',
    description: 'Tempat nongkrong santai dengan suasana hangat.',
    address: 'Jl. Ahmad Yani No. 45, Balikpapan',
    latitude: -1.2412,
    longitude: 116.8603,
    facilities: ['Outdoor', 'Wi-Fi', 'Musik'],
    atmosphere: ['Nongkrong', 'Healing'],
    categories: ['Nongkrong', 'Healing'],
    rating: 4.6,
    priceRange: 'Rp20k - Rp45k',
    images: const [],
    isActive: true,
  ),
  CafeModel(
    id: 'demo-3',
    name: 'Canvas & Beans',
    description: 'Cafe kreatif untuk belajar dan bekerja ringan.',
    address: 'Jl. MT Haryono No. 88, Balikpapan',
    latitude: -1.2298,
    longitude: 116.8451,
    facilities: ['Wi-Fi', 'Colokan', 'AC'],
    atmosphere: ['Kreatif', 'Belajar'],
    categories: ['Belajar', 'Kreatif'],
    rating: 4.7,
    priceRange: 'Rp18k - Rp40k',
    images: const [],
    isActive: true,
  ),
];
