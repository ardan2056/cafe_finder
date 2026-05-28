import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/admin_cafe_service.dart';
import '../../services/admin_image_picker.dart';
import '../../services/image_uploader.dart';

class AddCafeScreen extends StatefulWidget {
  const AddCafeScreen({super.key});

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

  bool isLoading = false;
  bool isUploadingImages = false;

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

  Future<void> saveCafe() async {
    if (nameController.text.isEmpty ||
        addressController.text.isEmpty ||
        latitudeController.text.isEmpty ||
        longitudeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data utama wajib diisi')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // validate image URLs and remove invalid ones
      final rawImages = imagesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final invalid = rawImages.where((u) => !_isValidUrl(u)).toList();
      var images = rawImages.where((u) => _isValidUrl(u)).toList();
      if (invalid.isNotEmpty) {
        imagesController.text = images.join(', ');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${invalid.length} invalid image URL(s) removed')),
          );
        }
      }

      await service.addCafe(
        name: nameController.text,
        description: descriptionController.text,
        address: addressController.text,
        latitude: double.parse(latitudeController.text),
        longitude: double.parse(longitudeController.text),
        facilities: selectedFacilities,
        atmosphere: selectedAtmosphere,
        categories: selectedCategories,
        priceRange: priceController.text,
        images: images,
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kafe berhasil ditambahkan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan kafe: $e')),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
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

    final valid = urls.where(_isValidUrl).toList();

    if (valid.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: valid.map((url) {
          return GestureDetector(
            onTap: () => _removeImageUrl(url),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white54),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _onPickImages() async {
    setState(() => isUploadingImages = true);
    try {
      final picked = await pickImages();
      if (picked.isEmpty) return;

      // Upload picked images when applicable and get back usable URLs
      final cafeId = DateTime.now().millisecondsSinceEpoch.toString();
      final uploaded = await uploadImagesIfNeeded(picked, cafeId: cafeId);

      final current = imagesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final merged = [...current, ...uploaded];
      imagesController.text = merged.join(', ');
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload gambar: $e')),
        );
      }
    } finally {
      setState(() => isUploadingImages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Tambah Kafe'),
        backgroundColor: AppTheme.navy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            inputField('Nama Kafe', nameController),
            inputField('Deskripsi', descriptionController),
            inputField('Alamat', addressController),
            inputField('Latitude', latitudeController),
            inputField('Longitude', longitudeController),
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
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
                    : const Text(
                        'Simpan Kafe',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
