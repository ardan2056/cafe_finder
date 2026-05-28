import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cafe_model.dart';
import '../../services/favorite_service.dart';
import '../../services/review_service.dart';
import '../review/review_screen.dart';

class CafeDetailScreen extends StatelessWidget {
  CafeDetailScreen({super.key});

  final FavoriteService favoriteService = FavoriteService();

  Future<void> openMaps(CafeModel cafe) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${cafe.latitude},${cafe.longitude}';

    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cafe = ModalRoute.of(context)!.settings.arguments as CafeModel;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 16),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.gold.withValues(alpha: 0.75),
                      AppTheme.blue.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_cafe_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                cafe.name,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppTheme.gold),
                  const SizedBox(width: 6),
                  Text(cafe.rating.toString()),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on_rounded, color: AppTheme.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cafe.address,
                      style: const TextStyle(color: AppTheme.lightGray),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                cafe.description,
                style: const TextStyle(
                  color: AppTheme.lightGray,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              sectionTitle('Kategori'),
              chipWrap(cafe.categories),
              const SizedBox(height: 24),
              sectionTitle('Fasilitas'),
              chipWrap(cafe.facilities),
              const SizedBox(height: 24),
              sectionTitle('Suasana'),
              chipWrap(cafe.atmosphere),
              const SizedBox(height: 24),
              sectionTitle('Range Harga'),
              Text(
                cafe.priceRange,
                style: const TextStyle(color: AppTheme.lightGray),
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => openMaps(cafe),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Buka Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewScreen(cafeId: cafe.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.rate_review_rounded),
                  label: const Text('Tulis Review'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.gold,
                    side: const BorderSide(color: AppTheme.gold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              sectionTitle('Ulasan Pengguna'),
              StreamBuilder(
                stream: ReviewService().getReviews(cafe.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text(
                      'Belum ada ulasan',
                      style: TextStyle(color: AppTheme.lightGray),
                    );
                  }

                  final reviews = snapshot.data!.docs;

                  if (reviews.isEmpty) {
                    return const Text(
                      'Belum ada ulasan',
                      style: TextStyle(color: AppTheme.lightGray),
                    );
                  }

                  return Column(
                    children: reviews.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['userName'] ?? 'Pengguna',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('⭐ ${data['rating']}'),
                            const SizedBox(height: 6),
                            Text(
                              data['comment'] ?? '',
                              style: const TextStyle(
                                color: AppTheme.lightGray,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 14),
              StreamBuilder<bool>(
                stream: favoriteService.isFavorite(cafe.id),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (isFavorite) {
                          await favoriteService.removeFavorite(cafe.id);
                        } else {
                          await favoriteService.addFavorite(cafe.id);
                        }
                      },
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                      label: Text(
                        isFavorite ? 'Hapus dari Favorit' : 'Simpan Favorit',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget chipWrap(List<String> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.gold.withValues(alpha: 0.3),
            ),
          ),
          child: Text(item),
        );
      }).toList(),
    );
  }
}
