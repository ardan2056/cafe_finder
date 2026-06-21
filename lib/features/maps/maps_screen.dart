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

  void _showRadiusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4C3BA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Pilih Jangkauan (Radius)',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              ..._radiusOptions.entries.map((entry) {
                final isSelected = _selectedRadiusMeters == entry.key;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.text,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedRadiusMeters = entry.key;
                    });
                    _savePreferences();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showMapSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4C3BA),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Pengaturan Tampilan Peta',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Grup Marker (Clustering)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Mengelompokkan penanda kafe yang berdekatan agar terlihat rapi.',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: AppTheme.primary,
                    value: _useClustering,
                    onChanged: (bool value) {
                      setModalState(() {
                        _useClustering = value;
                      });
                      setState(() {
                        _useClustering = value;
                      });
                    },
                  ),
                  const Divider(color: Color(0xFFD4C3BA), height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Tampilkan Lingkaran Radius',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Menampilkan area lingkaran jangkauan pencarian di peta.',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: AppTheme.primary,
                    value: _showCircle,
                    onChanged: (bool value) {
                      setModalState(() {
                        _showCircle = value;
                      });
                      setState(() {
                        _showCircle = value;
                      });
                      _savePreferences();
                    },
                  ),
                  const Divider(color: Color(0xFFD4C3BA), height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Alat Diagnostik',
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.network_check_rounded, size: 18),
                      label: const Text('Tes Koneksi Tile Peta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _testTileFetch();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFD4C3BA).withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: isSelected ? 0.12 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.text,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFD4C3BA).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: AppTheme.text,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Cari tempat atau alamat...',
                                hintStyle: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppTheme.primary,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          color: AppTheme.textLight,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchSuggestions = [];
                                          });
                                        },
                                      )
                                    : null,
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
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFD4C3BA).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: AppTheme.primary,
                            ),
                            onPressed: () => _showMapSettingsBottomSheet(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Jangkauan: ${_radiusOptions[_selectedRadiusMeters]}',
                            icon: Icons.keyboard_arrow_down_rounded,
                            isSelected: _selectedRadiusMeters > 0,
                            onTap: () => _showRadiusPicker(context),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Urutan: ${_sortBy == 'distance' ? 'Jarak' : 'Nama'}',
                            icon: Icons.swap_vert_rounded,
                            isSelected: true,
                            onTap: () {
                              setState(() {
                                _sortBy = _sortBy == 'distance' ? 'name' : 'distance';
                              });
                            },
                          ),
                          if (_selectedRadiusMeters > 0 && _currentPosition != null) ...[
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'Fit Peta',
                              icon: Icons.center_focus_strong_rounded,
                              isSelected: false,
                              onTap: () {
                                final zoom = _zoomForRadius(_selectedRadiusMeters);
                                _mapController.move(
                                    LatLng(_currentPosition!.latitude,
                                        _currentPosition!.longitude),
                                    zoom);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_searchSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFD4C3BA).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final s = _searchSuggestions[index];
                            return ListTile(
                              title: Text(
                                s.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.text,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () {
                                _searchController.text = s.displayName;
                                _searchSuggestions = [];
                                _mapController.move(LatLng(s.lat, s.lon), 15);
                                setState(() {});
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFD4C3BA)),
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
                                      width: 90,
                                      height: 75,
                                      child: GestureDetector(
                                        onTap: () => _onCafeTap(context, c),
                                        child: _buildCafeMarker(context, c),
                                      ),
                                    );
                                  }),
                                ],
                                builder: (context, markers) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text('${markers.length}',
                                          style: const TextStyle(
                                              color: Colors.white,
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
                                          color: AppTheme.primary),
                                    ),
                                  ),
                                ...filtered.map((r) {
                                  final c = r['cafe'] as CafeModel;
                                  return Marker(
                                    point: LatLng(c.latitude, c.longitude),
                                    width: 90,
                                    height: 75,
                                    child: GestureDetector(
                                      onTap: () => _onCafeTap(context, c),
                                      child: _buildCafeMarker(context, c),
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
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppTheme.navy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          'Daftar Cafe Terdekat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final row = filtered[index];
                            final CafeModel cafe = row['cafe'] as CafeModel;
                            final double dist = row['dist'] as double;
                            final image = cafe.images.isNotEmpty ? cafe.images.first : '';
                            
                            return GestureDetector(
                              onTap: () {
                                _mapController.move(LatLng(cafe.latitude, cafe.longitude), 15);
                                _onCafeTap(context, cafe);
                              },
                              child: Container(
                                width: 290,
                                margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: AppTheme.cardDecoration(radius: 20),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: 72,
                                        height: 72,
                                        color: AppTheme.secondaryContainer.withValues(alpha: 0.3),
                                        child: image.isNotEmpty && image.startsWith('http')
                                            ? Image.network(
                                                image,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(
                                                  Icons.local_cafe_rounded,
                                                  color: AppTheme.primary,
                                                  size: 32,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.local_cafe_rounded,
                                                color: AppTheme.primary,
                                                size: 32,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            cafe.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppTheme.text,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            cafe.address,
                                            style: const TextStyle(
                                              color: AppTheme.textLight,
                                              fontSize: 11,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star_rounded,
                                                    color: AppTheme.tertiaryContainer,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${cafe.rating}',
                                                    style: TextStyle(
                                                      color: AppTheme.text,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_rounded,
                                                    color: AppTheme.secondary,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    _formatDistance(dist),
                                                    style: const TextStyle(
                                                      color: AppTheme.primary,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
    final heroImage = c.images.isNotEmpty ? c.images.first : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4C3BA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                    child: heroImage != null && heroImage.isNotEmpty
                        ? Image.network(
                            heroImage,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.local_cafe_rounded,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppTheme.tertiaryContainer, size: 18),
                          const SizedBox(width: 4),
                          Text(c.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.cafeDetail,
                          arguments: c,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Buka Detail Cafe', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () async {
                        final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${c.latitude},${c.longitude}',
                        );
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondary,
                        side: const BorderSide(color: AppTheme.secondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Icon(Icons.directions_rounded),
                    ),
                  ),
                ),
              ],
            )
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

  Widget _buildCafeMarker(BuildContext context, CafeModel c) {
    final hasImage = c.images.isNotEmpty && c.images.first.isNotEmpty;

    return Semantics(
      label: 'Cafe ${c.name}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cafe Name Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Pin / Photo Circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.gold, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: hasImage
                  ? Image.network(
                      c.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_cafe_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    )
                  : const Icon(
                      Icons.local_cafe_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
