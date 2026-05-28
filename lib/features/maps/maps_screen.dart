import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cafe_model.dart';
import '../../services/cafe_service.dart';

class MapsScreen extends StatefulWidget {
  final CafeService? cafeService;

  const MapsScreen({super.key, this.cafeService});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  late final CafeService cafeService;
  final MapController _mapController = MapController();

  Position? _currentPosition;

  String get _resolvedTileUrl {
    // Use a standard OpenStreetMap tile template as a safe default.
    return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  @override
  void initState() {
    super.initState();
    cafeService = widget.cafeService ?? CafeService();
    _requestPermissionAndLocate();
  }

  Future<void> _requestPermissionAndLocate() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied) return;
    }

    if (status == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() => _currentPosition = pos);
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

          final center = _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : LatLng(-1.2379, 116.8529);

          return Column(
            children: [
              Expanded(
                flex: 2,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: center, initialZoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate: _resolvedTileUrl,
                      additionalOptions: const <String, String>{},
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 45,
                        size: const Size(40, 40),
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
                        builder: (context, markers) {
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: AppTheme.gold, shape: BoxShape.circle),
                            child: Text('${markers.length}',
                                style: const TextStyle(color: Colors.black)),
                          );
                        },
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
}
