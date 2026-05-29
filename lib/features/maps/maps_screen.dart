import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// Cluster markers removed for compatibility with current flutter_map version
// import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

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

  Position? _currentPosition;

  String get _resolvedTileUrl {
    // Use CartoDB's Voyager tiles which are permissively available for modest use.
    return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  }

  @override
  void initState() {
    super.initState();
    cafeService = widget.cafeService ?? CafeService();
    _requestPermissionAndLocate();
  }

  /// Public API: center the map on the current position if available.
  void centerOnUser() {
    if (_currentPosition != null) {
      _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15);
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

          cafesWithDistance.sort(
              (a, b) => (a['dist'] as double).compareTo(b['dist'] as double));

          return Column(
            children: [
              // Search bar + map area
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
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
                            ...cafes.map((c) => Marker(
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
                                )),
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
                          itemCount: cafesWithDistance.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white24),
                          itemBuilder: (context, index) {
                            final row = cafesWithDistance[index];
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

  double _lonToTileX(double lon, int zoom) =>
      ((lon + 180) / 360) * math.pow(2, zoom);

  double _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        math.pow(2, zoom);
  }
}
