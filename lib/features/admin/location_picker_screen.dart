import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerScreen({super.key, required this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  bool _loadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _loadingCurrentLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
    } catch (_) {
      // ignore location errors and keep the initial location
    } finally {
      if (mounted) {
        setState(() => _loadingCurrentLocation = false);
      }
    }
  }

  void _setSelection(LatLng point) {
    setState(() => _selectedLocation = point);
  }

  void _moveTo(LatLng point) {
    _mapController.move(point, 16);
    _setSelection(point);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedLocation ?? widget.initialLocation;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Pilih Lokasi Cafe'),
        backgroundColor: AppTheme.navy,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sentuh peta untuk menentukan titik cafe.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${selected.latitude.toStringAsFixed(6)}   Lng: ${selected.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(color: AppTheme.lightGray),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: widget.initialLocation,
                        initialZoom: 15,
                        onTap: (_, point) => _setSelection(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          tileProvider: NetworkTileProvider(
                            headers: const {'User-Agent': 'cafe-finder/1.0'},
                          ),
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: selected,
                              width: 56,
                              height: 56,
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 48,
                                color: Colors.redAccent,
                              ),
                            ),
                            if (_currentLocation != null)
                              Marker(
                                point: _currentLocation!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  size: 30,
                                  color: AppTheme.gold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'picker_current_location',
                            backgroundColor: AppTheme.gold,
                            onPressed: _currentLocation == null ||
                                    _loadingCurrentLocation
                                ? null
                                : () => _moveTo(_currentLocation!),
                            child: _loadingCurrentLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded,
                                    color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, selected),
                    child: const Text('Gunakan Lokasi Ini'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
