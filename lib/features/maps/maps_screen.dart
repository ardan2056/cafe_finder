import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import '../../services/places_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cafe_model.dart';
import '../../services/cafe_service.dart';

class MapsScreen extends StatefulWidget {
  final CafeService? cafeService;

  const MapsScreen({super.key, this.cafeService});

  @override
  State<MapsScreen> createState() => MapsScreenState();
}

class MapsScreenState extends State<MapsScreen> {
  late final CafeService cafeService;
  final MapController _mapController = MapController();
  final _places = PlacesService();
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSuggestion> _searchSuggestions = [];
  Timer? _searchDebounce;

  Position? _currentPosition;
  // (removed mapEvent tracking) — animation uses currentPosition instead

  String get _resolvedTileUrl {
    // Use CartoDB's Voyager tiles which are permissively available for modest use.
    return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  }

  @override
  void initState() {
    super.initState();
    cafeService = widget.cafeService ?? CafeService();
    _requestPermissionAndLocate();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final r = prefs.getInt('map_radius') ?? 0;
      final v = prefs.getBool('map_show_circle') ?? true;
      setState(() {
        _selectedRadiusMeters = r;
        _showCircle = v;
      });
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('map_radius', _selectedRadiusMeters);
      await prefs.setBool('map_show_circle', _showCircle);
    } catch (_) {}
  }

  // Radius filter (meters). 0 means no filter (all).
  int _selectedRadiusMeters = 0;
  final Map<int, String> _radiusOptions = {
    0: 'Semua',
    500: '500 m',
    1000: '1 km',
    3000: '3 km',
    5000: '5 km',
    10000: '10 km',
  };

  // Sort options: 'distance' or 'name'
  String _sortBy = 'distance';
  bool _showCircle = true;
  bool _useClustering = true;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Public API: center the map on the current position if available.
  void centerOnUser() {
    if (_currentPosition != null) {
      animateTo(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15);
    }
  }

  /// Animate map center and zoom smoothly to [target] with [targetZoom].
  Future<void> animateTo(LatLng target, double targetZoom,
      {int steps = 15,
      Duration duration = const Duration(milliseconds: 600)}) async {
    // Use current position as animation start if available, otherwise jump.
    final startCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : null;
    final startZoom = _currentPosition != null ? 14.0 : targetZoom;
    if (startCenter == null) {
      _mapController.move(target, targetZoom);
      return;
    }

    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final lat = lerpDouble(startCenter.latitude, target.latitude, t)!;
      final lon = lerpDouble(startCenter.longitude, target.longitude, t)!;
      final z = startZoom + (targetZoom - startZoom) * t;
      _mapController.move(LatLng(lat, lon), z);
      await Future.delayed(duration ~/ steps);
    }
  }

  Future<void> _requestPermissionAndLocate() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied) {
        return;
      }
    }

    if (status == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPosition = pos;
      });
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
    } catch (_) {
      // ignore
    }
  }

  String _formatDistance(double meters) {
    if (meters.isInfinite) return '-';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: StreamBuilder<List<CafeModel>>(
        stream: cafeService.getCafes(),
        builder: (context, snapshot) {
          final cafes = snapshot.data ?? [];

          final List<Map<String, dynamic>> cafesWithDistance = cafes.map((c) {
            double distMeters = double.infinity;
            if (_currentPosition != null) {
              distMeters = Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  c.latitude,
                  c.longitude);
            }
            return {'cafe': c, 'dist': distMeters};
          }).toList();

          // Apply radius filter if selected
          final filtered = _selectedRadiusMeters > 0
              ? cafesWithDistance
                  .where((r) => (r['dist'] as double) <= _selectedRadiusMeters)
                  .toList()
              : cafesWithDistance;

          // Sorting
          if (_sortBy == 'distance') {
            filtered.sort(
                (a, b) => (a['dist'] as double).compareTo(b['dist'] as double));
          } else if (_sortBy == 'name') {
            filtered.sort((a, b) => (a['cafe'] as CafeModel)
                .name
                .compareTo((b['cafe'] as CafeModel).name));
          }

          return Column(
            children: [
              // Search bar + map area
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Cari tempat atau alamat (contoh: "cafe near me")',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: (q) {
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(
                                  const Duration(milliseconds: 350), () async {
                                if (q.trim().isEmpty) {
                                  if (!mounted) return;
                                  setState(() => _searchSuggestions = []);
                                  return;
                                }
                                try {
                                  final res = await _places.search(q, limit: 6);
                                  if (!mounted) return;
                                  setState(() => _searchSuggestions = res);
                                } catch (_) {
                                  if (!mounted) return;
                                  setState(() => _searchSuggestions = []);
                                }
                              });
                            },
                            onSubmitted: (q) => _searchPlace(q),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _testTileFetch,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.gold,
                              foregroundColor: Colors.black),
                          child: const Text('Test Tile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        DropdownButton<int>(
                          value: _selectedRadiusMeters,
                          dropdownColor: AppTheme.navy,
                          items: _radiusOptions.entries
                              .map((e) => DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(e.value,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _selectedRadiusMeters = v);
                            _savePreferences();
                          },
                        ),
                        const SizedBox(width: 12),
                        const Text('Urutkan:',
                            style: TextStyle(color: AppTheme.lightGray)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _sortBy,
                          dropdownColor: AppTheme.navy,
                          items: const [
                            DropdownMenuItem(
                                value: 'distance', child: Text('Jarak')),
                            DropdownMenuItem(
                                value: 'name', child: Text('Nama')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _sortBy = v);
                          },
                        ),
                        const Spacer(),
                        Row(children: [
                          IconButton(
                            onPressed: () {
                              setState(() => _useClustering = !_useClustering);
                            },
                            icon: Icon(
                                _useClustering
                                    ? Icons.scatter_plot
                                    : Icons.location_on_outlined,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () {
                              setState(() => _showCircle = !_showCircle);
                              _savePreferences();
                            },
                            icon: Icon(
                                _showCircle
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: (_selectedRadiusMeters > 0 &&
                                    _currentPosition != null)
                                ? () {
                                    final zoom =
                                        _zoomForRadius(_selectedRadiusMeters);
                                    _mapController.move(
                                        LatLng(_currentPosition!.latitude,
                                            _currentPosition!.longitude),
                                        zoom);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.gold,
                                foregroundColor: Colors.black),
                            child: const Text('Fit'),
                          ),
                        ]),
                        if (_selectedRadiusMeters > 0 &&
                            _currentPosition != null)
                          Text(
                              'Filter ${_radiusOptions[_selectedRadiusMeters]} dari posisi',
                              style:
                                  const TextStyle(color: AppTheme.lightGray)),
                      ],
                    ),
                    if (_searchSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final s = _searchSuggestions[index];
                            return ListTile(
                              title: Text(s.displayName,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              onTap: () {
                                _searchController.text = s.displayName;
                                _searchSuggestions = [];
                                _mapController.move(LatLng(s.lat, s.lon), 15);
                                setState(() {});
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemCount: _searchSuggestions.length,
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(),
                      children: [
                        TileLayer(
                          urlTemplate: _resolvedTileUrl,
                          subdomains: const ['a', 'b', 'c', 'd'],
                          tileProvider: NetworkTileProvider(
                            headers: {
                              'User-Agent': 'cafe-finder/1.0',
                              'Referer': 'https://github.com/your-repo'
                            },
                          ),
                        ),
                        if (_selectedRadiusMeters > 0 &&
                            _currentPosition != null &&
                            _showCircle)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: LatLng(_currentPosition!.latitude,
                                    _currentPosition!.longitude),
                                color: AppTheme.gold.withValues(alpha: 0.16),
                                borderStrokeWidth: 1,
                                borderColor: AppTheme.gold,
                                useRadiusInMeter: true,
                                radius: _selectedRadiusMeters.toDouble(),
                              ),
                            ],
                          ),
                        if (_useClustering)
                          MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                              maxClusterRadius: 120,
                              size: const Size(40, 40),
                              markers: [
                                if (_currentPosition != null)
                                  Marker(
                                    point: LatLng(_currentPosition!.latitude,
                                        _currentPosition!.longitude),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.my_location_rounded,
                                        color: AppTheme.gold),
                                  ),
                                ...filtered.map((r) {
                                  final c = r['cafe'] as CafeModel;
                                  return Marker(
                                    point: LatLng(c.latitude, c.longitude),
                                    width: 56,
                                    height: 56,
                                    child: GestureDetector(
                                      onTap: () => _onCafeTap(context, c),
                                      child: Semantics(
                                        label: 'Cafe ${c.name}',
                                        child: const Icon(Icons.location_on,
                                            color: Colors.red, size: 36),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                              builder: (context, markers) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${markers.length}',
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          MarkerLayer(
                            markers: [
                              if (_currentPosition != null)
                                Marker(
                                  point: LatLng(_currentPosition!.latitude,
                                      _currentPosition!.longitude),
                                  width: 40,
                                  height: 40,
                                  child: Semantics(
                                    label: 'Your location',
                                    child: const Icon(Icons.my_location_rounded,
                                        color: AppTheme.gold),
                                  ),
                                ),
                              ...filtered.map((r) {
                                final c = r['cafe'] as CafeModel;
                                return Marker(
                                  point: LatLng(c.latitude, c.longitude),
                                  width: 56,
                                  height: 56,
                                  child: GestureDetector(
                                    onTap: () => _onCafeTap(context, c),
                                    child: Semantics(
                                      label: 'Cafe ${c.name}',
                                      child: const Icon(Icons.location_on,
                                          color: Colors.red, size: 36),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                      ],
                    ),

                    // Floating buttons: center on user and fit to all markers
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            mini: true,
                            backgroundColor: AppTheme.gold,
                            heroTag: 'center_on_user',
                            onPressed: () {
                              if (_currentPosition != null) {
                                _mapController.move(
                                    LatLng(_currentPosition!.latitude,
                                        _currentPosition!.longitude),
                                    15);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Lokasi belum tersedia. Izinkan akses lokasi.')));
                              }
                            },
                            child: const Icon(Icons.my_location_rounded,
                                color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            heroTag: 'fit_bounds',
                            onPressed: () => _fitBoundsAll(cafes),
                            child: const Icon(Icons.fit_screen,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: AppTheme.navy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Daftar Cafe Terdekat',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white24),
                          itemBuilder: (context, index) {
                            final row = filtered[index];
                            final CafeModel cafe = row['cafe'] as CafeModel;
                            final double dist = row['dist'] as double;
                            return ListTile(
                              onTap: () => _mapController.move(
                                  LatLng(cafe.latitude, cafe.longitude), 15),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 6),
                              leading: const Icon(Icons.local_cafe_rounded,
                                  color: AppTheme.gold),
                              title: Text(cafe.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(cafe.address,
                                  style: const TextStyle(
                                      color: AppTheme.lightGray)),
                              trailing: Text(_formatDistance(dist),
                                  style: const TextStyle(
                                      color: AppTheme.lightGray)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onCafeTap(BuildContext context, CafeModel c) {
    _mapController.move(LatLng(c.latitude, c.longitude), 15);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
            color: AppTheme.navy,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(c.address, style: const TextStyle(color: AppTheme.lightGray)),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.cafeDetail,
                    arguments: c),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black),
                child: const Text('Buka detail'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${c.latitude},${c.longitude}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.06)),
                child: const Icon(Icons.directions),
              ),
            ])
          ],
        ),
      ),
    );
  }

  void _fitBoundsAll(List<CafeModel> cafes) {
    if (cafes.isEmpty) return;
    // Simplified: move to first cafe or current position instead of fitBounds
    final c = cafes.first;
    _mapController.move(LatLng(c.latitude, c.longitude), 15);
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search')
        .replace(queryParameters: {'q': query, 'format': 'json', 'limit': '5'});
    try {
      final res =
          await http.get(uri, headers: {'User-Agent': 'cafe-finder/1.0'});
      if (!mounted) {
        return;
      }
      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pencarian gagal: ${res.statusCode}')));
        return;
      }
      final List data = jsonDecode(res.body) as List;
      if (data.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Tidak ditemukan')));
        return;
      }

      final results = data.map((e) => e as Map<String, dynamic>).toList();
      // Show simple selection dialog
      if (!mounted) {
        return;
      }
      final choice = await showDialog<int?>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Hasil Pencarian'),
          children: results.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, i),
              child: Text(item['display_name'] ?? ''),
            );
          }).toList(),
        ),
      );

      if (choice == null) {
        return;
      }
      final sel = results[choice];
      final lat = double.tryParse(sel['lat'] ?? '');
      final lon = double.tryParse(sel['lon'] ?? '');
      if (lat == null || lon == null) {
        return;
      }
      _mapController.move(LatLng(lat, lon), 15);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Pencarian gagal: $e')));
    }
  }

  Future<void> _testTileFetch() async {
    // Test fetching a single tile for current center & zoom
    try {
      final zoom = 13;
      final center = _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : LatLng(-1.2379, 116.8529);
      final x = _lonToTileX(center.longitude, zoom).floor();
      final y = _latToTileY(center.latitude, zoom).floor();
      final url = _resolvedTileUrl
          .replaceAll('{s}', 'a')
          .replaceAll('{z}', '$zoom')
          .replaceAll('{x}', '$x')
          .replaceAll('{y}', '$y');
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'cafe-finder/1.0',
        'Referer': 'https://github.com/your-repo'
      });
      if (!mounted) {
        return;
      }
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tile berhasil diambil')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tile fetch failed: ${res.statusCode}')));
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Tile fetch error: $e')));
    }
  }

  double _zoomForRadius(int meters) {
    // Simple heuristic mapping radius to zoom level
    if (meters <= 500) return 15.0;
    if (meters <= 1000) return 14.0;
    if (meters <= 3000) return 12.5;
    if (meters <= 5000) return 11.5;
    return 10.0;
  }

  double _lonToTileX(double lon, int zoom) =>
      ((lon + 180) / 360) * math.pow(2, zoom);

  double _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        math.pow(2, zoom);
  }
}
