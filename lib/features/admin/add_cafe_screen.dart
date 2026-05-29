import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cafe_model.dart';
import '../../services/admin_cafe_service.dart';
import '../../services/admin_image_picker.dart';
import '../../services/image_uploader.dart';
import '../../core/firebase_status.dart' as fb_status;
import 'location_picker_screen.dart';
import '../../services/places_service.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class AddCafeScreen extends StatefulWidget {
  final CafeModel? cafe;

  const AddCafeScreen({super.key, this.cafe});

  @override
  State<AddCafeScreen> createState() => _AddCafeScreenState();
}

class _AddCafeScreenState extends State<AddCafeScreen> {
  final service = AdminCafeService();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  final priceController = TextEditingController();
  final imagesController = TextEditingController();
  final _places = PlacesService();
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;

  bool isLoading = false;
  bool isUploadingImages = false;
  late final bool isEditMode;
  final Map<String, double> _uploadProgress = {};
  Map<int, UploadTask> _uploadTasks = {};
  List<String> _lastPickedUploading = [];
  String? _lastUploadCafeId;
  final Map<String, String?> _uploadError = {};
  final Set<String> _retrying = {};

  final List<String> selectedFacilities = [];
  final List<String> selectedAtmosphere = [];
  final List<String> selectedCategories = [];

  final facilities = [
    'Wi-Fi',
    'Colokan',
    'AC',
    'Toilet',
    'Mushola',
    'Parkir',
    'Outdoor',
    'Smoking Area',
  ];

  final atmospheres = [
    'Tenang',
    'Ramai',
    'Cozy',
    'Estetik',
    'Kreatif',
    'Santai',
  ];

  final categories = [
    'Belajar',
    'Kerja',
    'Nongkrong',
    'Meeting',
    'Kreatif',
    'Healing',
  ];

  @override
  void initState() {
    super.initState();
    isEditMode = widget.cafe != null;
    final cafe = widget.cafe;
    if (cafe != null) {
      nameController.text = cafe.name;
      descriptionController.text = cafe.description;
      addressController.text = cafe.address;
      latitudeController.text = cafe.latitude.toString();
      longitudeController.text = cafe.longitude.toString();
      priceController.text = cafe.priceRange;
      imagesController.text = cafe.images.join(', ');
      selectedFacilities.addAll(cafe.facilities);
      selectedAtmosphere.addAll(cafe.atmosphere);
      selectedCategories.addAll(cafe.categories);
    }
  }

  Future<void> saveCafe() async {
    if (nameController.text.isEmpty ||
        addressController.text.isEmpty ||
        latitudeController.text.isEmpty ||
        longitudeController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data utama wajib diisi')),
        );
      }
      return;
    }

    

    // Validate numeric latitude/longitude
    final lat = double.tryParse(latitudeController.text);
    final lng = double.tryParse(longitudeController.text);
    if (lat == null || lng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Latitude dan Longitude harus berupa angka')),
        );
      }
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // validate image URLs and remove invalid ones
      final rawImages = imagesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final invalid = rawImages.where((u) => !_isValidUrl(u)).toList();
      final images = rawImages.where((u) => _isValidUrl(u)).toList();
      if (invalid.isNotEmpty) {
        imagesController.text = images.join(', ');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${invalid.length} invalid image URL(s) removed')),
          );
        }
      }

      if (isEditMode) {
        await service.updateCafe(
          cafeId: widget.cafe!.id,
          data: {
            'name': nameController.text,
            'description': descriptionController.text,
            'address': addressController.text,
            'latitude': lat,
            'longitude': lng,
            'facilities': selectedFacilities,
            'atmosphere': selectedAtmosphere,
            'categories': selectedCategories,
            'priceRange': priceController.text,
            'images': images,
          },
        );
      } else {
        await service.addCafe(
          name: nameController.text,
          description: descriptionController.text,
          address: addressController.text,
          latitude: lat,
          longitude: lng,
          facilities: selectedFacilities,
          atmosphere: selectedAtmosphere,
          categories: selectedCategories,
          priceRange: priceController.text,
          images: images,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode ? 'Kafe berhasil diperbarui' : 'Kafe berhasil ditambahkan',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode ? 'Gagal memperbarui kafe: $e' : 'Gagal menambahkan kafe: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _pickLocation() async {
    final initialLat = double.tryParse(latitudeController.text) ?? -1.2379;
    final initialLng = double.tryParse(longitudeController.text) ?? 116.8529;
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: LatLng(initialLat, initialLng),
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      latitudeController.text = result.latitude.toStringAsFixed(6);
      longitudeController.text = result.longitude.toStringAsFixed(6);
    });
  }

  void _cancelUploadFor(String src) {
    final idx = _lastPickedUploading.indexOf(src);
    if (idx >= 0) {
      final task = _uploadTasks[idx];
      try {
        task?.cancel();
      } catch (_) {}
      setState(() {
        _uploadProgress.remove(src);
        _uploadError.remove(src);
      });
    }
  }

  Future<void> _retryUploadFor(String src) async {
    if (_lastUploadCafeId == null) return;
    setState(() {
      _uploadProgress[src] = 0.0;
      _uploadError.remove(src);
      _retrying.add(src);
    });
    final out = <int, UploadTask>{};
    _uploadTasks = out;
    try {
      final uploaded = await uploadImagesIfNeeded([src],
          cafeId: _lastUploadCafeId!, outUploadTasks: out, onProgress: (i, p) {
        if (mounted) setState(() => _uploadProgress[src] = p.clamp(0.0, 1.0));
      });
      if (uploaded.isNotEmpty && uploaded[0].isNotEmpty) {
        if (mounted) {
          setState(() {
            imagesController.text = imagesController.text.replaceFirst(src, uploaded[0]);
            _uploadProgress.remove(src);
            _uploadError.remove(src);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError[src] = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _retrying.remove(src);
        });
      }
    }
  }

  Widget inputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _addressField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: addressController,
            decoration: InputDecoration(
              labelText: 'Alamat',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () async {
                if (value.trim().isEmpty) {
                  setState(() => _suggestions = []);
                  return;
                }
                try {
                  final results = await _places.search(value, limit: 6);
                  if (!mounted) return;
                  setState(() => _suggestions = results);
                } catch (_) {
                  if (!mounted) return;
                  setState(() => _suggestions = []);
                }
              });
            },
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final s = _suggestions[index];
                  return ListTile(
                    title: Text(s.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      addressController.text = s.displayName;
                      latitudeController.text = s.lat.toStringAsFixed(6);
                      longitudeController.text = s.lon.toStringAsFixed(6);
                      setState(() => _suggestions = []);
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: _suggestions.length,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    priceController.dispose();
    imagesController.dispose();
    super.dispose();
  }

  Widget chipSelector(
    String title,
    List<String> items,
    List<String> selectedItems,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            final selected = selectedItems.contains(item);

            return GestureDetector(
              onTap: () {
                setState(() {
                  selected
                      ? selectedItems.remove(item)
                      : selectedItems.add(item);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.gold
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  void _removeImageUrl(String url) {
    final list = imagesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s != url)
        .toList();
    imagesController.text = list.join(', ');
    setState(() {});
  }

  Widget imagePreview() {
    final urls = imagesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (urls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: urls.map((src) {
          Widget imgWidget;
          if (_isValidUrl(src)) {
            imgWidget = Image.network(
              src,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.white54),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)));
              },
            );
          } else if (src.startsWith('data:')) {
            try {
              final comma = src.indexOf(',');
              final payload = src.substring(comma + 1);
              final isBase64 = src.substring(5, comma).contains('base64');
              final bytes = isBase64 ? base64Decode(payload) : Uint8List.fromList(utf8.encode(Uri.decodeComponent(payload)));
              imgWidget = Image.memory(bytes, fit: BoxFit.cover);
            } catch (_) {
              imgWidget = const Icon(Icons.broken_image, color: Colors.white54);
            }
          } else {
            final file = File(src);
            if (file.existsSync()) {
              imgWidget = Image.file(file, fit: BoxFit.cover);
            } else {
              imgWidget = const Icon(Icons.broken_image, color: Colors.white54);
            }
          }

          final progress = _uploadProgress[src];
          final hasError = _uploadError.containsKey(src);
          final isRetrying = _retrying.contains(src);
          final isUploading = progress != null && progress < 1.0;

          return GestureDetector(
            onTap: () => _removeImageUrl(src),
            child: Semantics(
              label: 'Hapus gambar',
              button: true,
              child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imgWidget,
                    if (isUploading)
                      Container(
                        color: Colors.black26,
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: isUploading
                          ? GestureDetector(
                              onTap: () => _cancelUploadFor(src),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.cancel, size: 16, color: Colors.white),
                              ),
                            )
                          : hasError
                              ? GestureDetector(
                                  onTap: isRetrying ? null : () => _retryUploadFor(src),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isRetrying ? Colors.orange.shade700 : Colors.black45,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: isRetrying
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.refresh, size: 16, color: Colors.white),
                                  ),
                                )
                              : (!_isValidUrl(src)
                                  ? GestureDetector(
                                      onTap: isRetrying ? null : () => _retryUploadFor(src),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isRetrying ? Colors.orange.shade700 : Colors.black45,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: isRetrying
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.refresh, size: 16, color: Colors.white),
                                      ),
                                    )
                                  : const SizedBox.shrink())),
                    if (hasError)
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Tooltip(
                          message: _uploadError[src] ?? 'Upload error',
                          child: Icon(Icons.error_outline, size: 16, color: Colors.redAccent.withValues(alpha: 0.9)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        }).toList(),
      ),
    );
  }

  Future<void> _onPickImages() async {
    if (!fb_status.isFirebaseReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Firebase belum siap — upload gambar dinonaktifkan.')));
      return;
    }

    final picked = await pickImages();
    if (picked.isEmpty) return;

    // Optimistic UI: append local paths immediately so previews appear
    final current = imagesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final merged = [...current, ...picked];
    imagesController.text = merged.join(', ');
    setState(() {});

    // Start background upload (do not block UI)
    setState(() {
      isUploadingImages = true;
      for (final p in picked) {
        _uploadProgress[p] = 0.0;
      }
    });
    final cafeId = DateTime.now().millisecondsSinceEpoch.toString();
    _lastPickedUploading = picked;
    _lastUploadCafeId = cafeId;
    final out = <int, UploadTask>{};
    setState(() => _uploadTasks = out);
    uploadImagesIfNeeded(picked, cafeId: cafeId, outUploadTasks: out, onProgress: (index, progress) {
      final key = picked[index];
      if (mounted) {
        setState(() {
          _uploadProgress[key] = progress.clamp(0.0, 1.0);
        });
      }
    }).then((uploaded) {
      // Replace occurrences of local paths with uploaded URLs in order
      var text = imagesController.text;
      for (var i = 0; i < picked.length; i++) {
        final local = picked[i];
        final uploadedUrl = i < uploaded.length ? uploaded[i] : null;
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          text = text.replaceFirst(local, uploadedUrl);
          // mark progress as complete for replacement key
          _uploadProgress.remove(local);
        }
      }
      imagesController.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload gambar selesai')));
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload gambar: $e')));
      }
    }).whenComplete(() => setState(() => isUploadingImages = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Kafe' : 'Tambah Kafe'),
        backgroundColor: AppTheme.navy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            inputField('Nama Kafe', nameController),
            inputField('Deskripsi', descriptionController),
            _addressField(),
            inputField('Latitude', latitudeController),
            inputField('Longitude', longitudeController),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Pilih dari Peta'),
                    ),
                  ),
                ],
              ),
            ),
            inputField('Range Harga', priceController),
            chipSelector('Fasilitas', facilities, selectedFacilities),
            chipSelector('Suasana', atmospheres, selectedAtmosphere),
            chipSelector('Kategori', categories, selectedCategories),
            inputField('Image URLs (comma separated)', imagesController),
            Row(
              children: [
                ElevatedButton(
                  onPressed: isUploadingImages ? null : _onPickImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                  ),
                  child: isUploadingImages
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.photo_library_outlined),
                            SizedBox(width: 8),
                            Text('Pick Images'),
                          ],
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(child: imagePreview()),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveCafe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        isEditMode ? 'Simpan Perubahan' : 'Simpan Kafe',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
