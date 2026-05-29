import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../models/cafe_model.dart';
import '../../services/admin_cafe_service.dart';
import '../../services/cafe_service_web.dart';
import 'add_cafe_screen.dart';

class AdminCafeManagerScreen extends StatefulWidget {
  const AdminCafeManagerScreen({super.key});

  @override
  State<AdminCafeManagerScreen> createState() => _AdminCafeManagerScreenState();
}

class _AdminCafeManagerScreenState extends State<AdminCafeManagerScreen> {
  final _searchController = TextEditingController();
  final _adminService = AdminCafeService();
  final _cafeService = CafeService();
  final Set<String> _busyIds = <String>{};
  final Set<String> _selectedIds = <String>{};
  Position? _currentPosition;
  String _query = '';
  String _statusFilter = 'all';
  String _categoryFilter = 'all';
  String _sortFilter = 'active';
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setActive(CafeModel cafe, bool isActive) async {
    setState(() => _busyIds.add(cafe.id));
    try {
      await _adminService.setCafeActive(cafeId: cafe.id, isActive: isActive);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? '${cafe.name} berhasil diaktifkan'
                : '${cafe.name} dinonaktifkan',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(cafe.id));
      }
    }
  }

  Future<void> _deleteCafe(CafeModel cafe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus cafe?'),
        content: Text(
          'Cafe "${cafe.name}" akan dihapus permanen dari katalog. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busyIds.add(cafe.id));
    try {
      await _adminService.deleteCafe(cafeId: cafe.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${cafe.name} berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus cafe: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(cafe.id));
      }
    }
  }

  Future<void> _duplicateCafe(CafeModel cafe) async {
    setState(() => _busyIds.add(cafe.id));
    try {
      await _adminService.duplicateCafe(
        name: '${cafe.name} Copy',
        description: cafe.description,
        address: cafe.address,
        latitude: cafe.latitude,
        longitude: cafe.longitude,
        facilities: List<String>.from(cafe.facilities),
        atmosphere: List<String>.from(cafe.atmosphere),
        categories: List<String>.from(cafe.categories),
        priceRange: cafe.priceRange,
        images: List<String>.from(cafe.images),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${cafe.name} berhasil diduplikasi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menduplikasi cafe: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(cafe.id));
      }
    }
  }

  void _toggleSelected(String cafeId, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(cafeId);
      } else {
        _selectedIds.remove(cafeId);
      }
    });
  }

  void _toggleSelectVisible(List<CafeModel> visibleCafes) {
    final visibleIds = visibleCafes.map((cafe) => cafe.id).toSet();
    final allVisibleSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedIds.contains);
    setState(() {
      if (allVisibleSelected) {
        _selectedIds.removeAll(visibleIds);
      } else {
        _selectedIds.addAll(visibleIds);
      }
    });
  }

  Future<void> _bulkDeleteSelected(List<CafeModel> visibleCafes) async {
    final selectedCafes =
        visibleCafes.where((cafe) => _selectedIds.contains(cafe.id)).toList();
    if (selectedCafes.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus cafe terpilih?'),
        content: Text(
          'Kamu akan menghapus ${selectedCafes.length} cafe dari katalog. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _busyIds.addAll(selectedCafes.map((cafe) => cafe.id));
    });

    try {
      for (final cafe in selectedCafes) {
        await _adminService.deleteCafe(cafeId: cafe.id);
      }
      if (!mounted) return;
      setState(() {
        _selectedIds.removeAll(selectedCafes.map((cafe) => cafe.id));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${selectedCafes.length} cafe berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus cafe terpilih: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.removeAll(selectedCafes.map((cafe) => cafe.id));
        });
      }
    }
  }

  Future<void> _bulkUpdateActive(
      List<CafeModel> visibleCafes, bool isActive) async {
    final selectedCafes =
        visibleCafes.where((cafe) => _selectedIds.contains(cafe.id)).toList();
    if (selectedCafes.isEmpty) return;

    setState(() {
      _busyIds.addAll(selectedCafes.map((cafe) => cafe.id));
    });

    try {
      for (final cafe in selectedCafes) {
        await _adminService.setCafeActive(cafeId: cafe.id, isActive: isActive);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selectedCafes.length} cafe berhasil ${isActive ? 'diaktifkan' : 'dinonaktifkan'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui cafe terpilih: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.removeAll(selectedCafes.map((cafe) => cafe.id));
        });
      }
    }
  }

  List<String> _parseCategories(String input) {
    return input
        .split(RegExp(r'[\n,]'))
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _bulkEditCategories(List<CafeModel> visibleCafes) async {
    final selectedCafes =
        visibleCafes.where((cafe) => _selectedIds.contains(cafe.id)).toList();
    if (selectedCafes.isEmpty) return;

    final controller = TextEditingController();
    var replaceMode = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit kategori terpilih'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Masukkan kategori dipisahkan koma atau baris baru untuk ${selectedCafes.length} cafe terpilih.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  hintText: 'manual brew, wifi, outdoor',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: replaceMode,
                onChanged: (value) => setDialogState(() => replaceMode = value),
                title: const Text('Ganti kategori lama'),
                subtitle: const Text(
                    'Matikan untuk menambahkan kategori baru ke yang lama.'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final categories = _parseCategories(controller.text);
                if (categories.isEmpty) return;
                Navigator.pop(context, {
                  'categories': categories,
                  'replace': replaceMode,
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (result == null) return;

    final categories = List<String>.from(result['categories'] as List);
    final replace = result['replace'] as bool;

    setState(() {
      _busyIds.addAll(selectedCafes.map((cafe) => cafe.id));
    });

    try {
      for (final cafe in selectedCafes) {
        final nextCategories = replace
            ? categories
            : {
                ...cafe.categories,
                ...categories,
              }.toList();
        await _adminService.updateCafe(
          cafeId: cafe.id,
          data: {'categories': nextCategories},
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${selectedCafes.length} cafe berhasil diperbarui kategorinya')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui kategori terpilih: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.removeAll(selectedCafes.map((cafe) => cafe.id));
        });
      }
    }
  }

  Future<void> _openEditor([CafeModel? cafe]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCafeScreen(cafe: cafe),
      ),
    );
  }

  bool _matchesStatusFilter(CafeModel cafe) {
    switch (_statusFilter) {
      case 'active':
        return cafe.isActive;
      case 'inactive':
        return !cafe.isActive;
      default:
        return true;
    }
  }

  bool _matchesCategoryFilter(CafeModel cafe) {
    if (_categoryFilter == 'all') return true;
    return cafe.categories.any((category) => category == _categoryFilter);
  }

  void _resetFilters() {
    setState(() {
      _query = '';
      _statusFilter = 'all';
      _categoryFilter = 'all';
      _sortFilter = 'active';
      _selectedIds.clear();
      _searchController.clear();
    });
  }

  Future<void> _refreshCurrentLocation() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi belum diberikan')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _currentPosition = position);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lokasi diperbarui: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil lokasi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  List<MapEntry<String, int>> _topCategories(List<CafeModel> cafes,
      {int limit = 3}) {
    final counts = <String, int>{};
    for (final cafe in cafes) {
      for (final category in cafe.categories) {
        final key = category.trim();
        if (key.isEmpty) continue;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return entries.take(limit).toList();
  }

  double _distanceToCafe(CafeModel cafe) {
    if (_currentPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      cafe.latitude,
      cafe.longitude,
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.lightGray)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightPanel({
    required int total,
    required int active,
    required int inactive,
    required int visible,
    required List<MapEntry<String, int>> topCategories,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppTheme.gold),
              const SizedBox(width: 8),
              const Text(
                'Ringkasan cepat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Reset filter'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final cards = [
                _metricCard('Total cafe', '$total', Icons.local_cafe_rounded,
                    AppTheme.gold),
                _metricCard('Aktif', '$active', Icons.check_circle_rounded,
                    Colors.greenAccent),
                _metricCard('Nonaktif', '$inactive', Icons.pause_circle_rounded,
                    Colors.orangeAccent),
                _metricCard('Tertampil', '$visible', Icons.visibility_rounded,
                    Colors.cyanAccent),
              ];

              if (isWide) {
                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      Expanded(child: cards[i]),
                      if (i != cards.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: card,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          if (topCategories.isNotEmpty) ...[
            const Text(
              'Kategori teratas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: topCategories
                  .map(
                    (entry) => Chip(
                      avatar: const Icon(Icons.sell_rounded, size: 16),
                      label: Text('${entry.key} • ${entry.value}'),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<CafeModel> _sortCafes(List<CafeModel> cafes) {
    final sorted = List<CafeModel>.from(cafes);
    switch (_sortFilter) {
      case 'distance':
        sorted.sort((a, b) {
          final distanceCompare =
              _distanceToCafe(a).compareTo(_distanceToCafe(b));
          if (distanceCompare != 0) return distanceCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case 'name':
        sorted.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'rating':
        sorted.sort((a, b) {
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) return ratingCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case 'inactive':
        sorted.sort((a, b) {
          if (a.isActive != b.isActive) {
            return a.isActive ? 1 : -1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      default:
        sorted.sort((a, b) {
          if (a.isActive != b.isActive) {
            return a.isActive ? -1 : 1;
          }
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) return ratingCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
    }
    return sorted;
  }

  Widget _statusChip(String value, String label, int count) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      onSelected: (_) => setState(() => _statusFilter = value),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppTheme.gold,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    );
  }

  Widget _categoryChip(String value, String label, int count) {
    final isSelected = _categoryFilter == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      onSelected: (_) => setState(() => _categoryFilter = value),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: Colors.cyanAccent,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Kelola Cafe'),
        backgroundColor: AppTheme.navy,
        actions: [
          IconButton(
            tooltip: 'Reset filter',
            onPressed: _resetFilters,
            icon: const Icon(Icons.filter_alt_off_rounded),
          ),
          IconButton(
            tooltip: 'Tambah cafe',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<CafeModel>>(
        stream: _cafeService.getCafes(),
        builder: (context, snapshot) {
          final cafes = snapshot.data ?? const <CafeModel>[];
          final categories = cafes
              .expand((cafe) => cafe.categories)
              .where((category) => category.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          final filtered = cafes.where((cafe) {
            if (!_matchesStatusFilter(cafe)) return false;
            if (!_matchesCategoryFilter(cafe)) return false;
            if (_query.trim().isEmpty) return true;
            final q = _query.toLowerCase();
            return cafe.name.toLowerCase().contains(q) ||
                cafe.address.toLowerCase().contains(q) ||
                cafe.categories.any((c) => c.toLowerCase().contains(q));
          }).toList();
          final ordered = _sortCafes(filtered);
          final visibleIds = ordered.map((cafe) => cafe.id).toSet();
          final selectedVisibleCount =
              _selectedIds.where(visibleIds.contains).length;
          final allVisibleSelected =
              ordered.isNotEmpty && selectedVisibleCount == ordered.length;
          final topCategories = _topCategories(cafes);

          final activeCount = cafes.where((c) => c.isActive).length;
          final inactiveCount = cafes.length - activeCount;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow(cafes.length, activeCount, inactiveCount),
                const SizedBox(height: 16),
                _buildInsightPanel(
                  total: cafes.length,
                  active: activeCount,
                  inactive: inactiveCount,
                  visible: ordered.length,
                  topCategories: topCategories,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, alamat, atau kategori',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _statusChip('all', 'Semua', cafes.length),
                      _statusChip('active', 'Aktif', activeCount),
                      _statusChip('inactive', 'Nonaktif', inactiveCount),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (categories.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _categoryChip('all', 'Semua kategori', cafes.length),
                        ...categories.map(
                          (category) => _categoryChip(
                            category,
                            category,
                            cafes
                                .where((cafe) =>
                                    cafe.categories.contains(category))
                                .length,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sortFilter,
                        decoration: InputDecoration(
                          labelText: 'Urutkan',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: AppTheme.navy,
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Aktif dulu'),
                          ),
                          DropdownMenuItem(
                            value: 'distance',
                            child: Text('Jarak terdekat'),
                          ),
                          DropdownMenuItem(
                            value: 'rating',
                            child: Text('Rating tertinggi'),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('Nama A-Z'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Nonaktif dulu'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _sortFilter = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed:
                          _isLoadingLocation ? null : _refreshCurrentLocation,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(
                        _currentPosition == null
                            ? 'Ambil lokasi saya'
                            : 'Perbarui lokasi',
                      ),
                    ),
                  ],
                ),
                if (_currentPosition != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lokasi aktif: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(color: AppTheme.lightGray),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${ordered.length} cafe ditampilkan',
                    style: const TextStyle(color: AppTheme.lightGray),
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedVisibleCount > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.18)),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '$selectedVisibleCount cafe terpilih',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _toggleSelectVisible(ordered),
                          icon: Icon(allVisibleSelected
                              ? Icons.deselect_rounded
                              : Icons.select_all_rounded),
                          label: Text(allVisibleSelected
                              ? 'Batal pilih tampil'
                              : 'Pilih semua tampil'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _bulkUpdateActive(ordered, true),
                          icon: const Icon(Icons.visibility_rounded),
                          label: const Text('Aktifkan terpilih'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _bulkUpdateActive(ordered, false),
                          icon: const Icon(Icons.visibility_off_rounded),
                          label: const Text('Nonaktifkan terpilih'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _bulkEditCategories(ordered),
                          icon: const Icon(Icons.category_rounded),
                          label: const Text('Edit kategori'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _bulkDeleteSelected(ordered),
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text('Hapus terpilih'),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                        ),
                        TextButton(
                          onPressed: () => setState(_selectedIds.clear),
                          child: const Text('Bersihkan pilihan'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting &&
                          cafes.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ordered.isEmpty
                          ? _emptyState(cafes.isEmpty)
                          : ListView.separated(
                              itemCount: ordered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final cafe = ordered[index];
                                final isBusy = _busyIds.contains(cafe.id);
                                final isSelected =
                                    _selectedIds.contains(cafe.id);
                                return _CafeAdminCard(
                                  cafe: cafe,
                                  isBusy: isBusy,
                                  isSelected: isSelected,
                                  onSelectionChanged: (value) =>
                                      _toggleSelected(cafe.id, value ?? false),
                                  onEdit: () => _openEditor(cafe),
                                  onDuplicate: () => _duplicateCafe(cafe),
                                  onToggleActive: () =>
                                      _setActive(cafe, !cafe.isActive),
                                  onDelete: () => _deleteCafe(cafe),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(int total, int active, int inactive) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: 'Total', value: '$total')),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(label: 'Aktif', value: '$active')),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(label: 'Nonaktif', value: '$inactive')),
      ],
    );
  }

  Widget _emptyState(bool noData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noData ? Icons.local_cafe_rounded : Icons.search_off_rounded,
              size: 72,
              color: AppTheme.gold.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              noData ? 'Belum ada data cafe' : 'Tidak ada hasil yang cocok',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              noData
                  ? 'Tambahkan cafe pertama untuk mulai mengelola katalog.'
                  : 'Coba kata kunci lain untuk menemukan cafe.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.lightGray),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Cafe'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.lightGray)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CafeAdminCard extends StatelessWidget {
  final CafeModel cafe;
  final bool isBusy;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _CafeAdminCard({
    required this.cafe,
    required this.isBusy,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.onDuplicate,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        cafe.isActive ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 6),
                child: Checkbox(
                  value: isSelected,
                  onChanged: onSelectionChanged,
                  activeColor: AppTheme.gold,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64,
                  height: 64,
                  color: Colors.white.withValues(alpha: 0.08),
                  child: cafe.images.isNotEmpty
                      ? Image.network(
                          cafe.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_cafe_rounded,
                            color: Colors.white54,
                          ),
                        )
                      : const Icon(Icons.local_cafe_rounded,
                          color: Colors.white54),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cafe.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            cafe.isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cafe.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.lightGray),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniInfo(
                            icon: Icons.star_rounded,
                            text: cafe.rating.toStringAsFixed(1)),
                        _MiniInfo(
                            icon: Icons.payments_rounded,
                            text: cafe.priceRange),
                        _MiniInfo(
                            icon: Icons.place_rounded,
                            text:
                                '${cafe.latitude.toStringAsFixed(4)}, ${cafe.longitude.toStringAsFixed(4)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (cafe.categories.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cafe.categories
                  .take(4)
                  .map(
                    (category) => Chip(
                      label: Text(category),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onToggleActive,
                  icon: Icon(cafe.isActive
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded),
                  label: Text(cafe.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : onDuplicate,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Duplikat Cafe'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Hapus'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
          if (isBusy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.gold),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
