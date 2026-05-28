import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cafe_model.dart';
import '../../services/cafe_service.dart';
import '../../services/favorite_service.dart';

class FavoriteScreen extends StatelessWidget {
  FavoriteScreen({super.key});

  final FavoriteService favoriteService = FavoriteService();
  final CafeService cafeService = CafeService();

  Widget buildWebPlaceholder() {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite_rounded,
                        color: AppTheme.gold, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Favorit',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Simpan cafe pilihanmu dan lihat kembali nanti. Di web ini tampil sebagai preview.',
                            style: TextStyle(color: AppTheme.lightGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: favoriteService.favoriteIds(),
                  builder: (context, favSnap) {
                    final favIds = favSnap.data ?? [];

                    if (favIds.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_border_rounded,
                                color: AppTheme.gold,
                                size: 56,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Belum ada cafe favorit',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pilih cafe di Home atau Search untuk menambahkannya ke daftar favorit.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.lightGray),
                            ),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<List<CafeModel>>(
                      stream: cafeService.getCafes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.gold,
                            ),
                          );
                        }

                        final cafes = snapshot.data!
                            .where((cafe) => favIds.contains(cafe.id))
                            .toList();

                        if (cafes.isEmpty) {
                          return const Center(
                            child: Text('Belum ada kafe favorit'),
                          );
                        }

                        return ListView.builder(
                          itemCount: cafes.length,
                          itemBuilder: (context, index) {
                            final cafe = cafes[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.cafeDetail,
                                  arguments: cafe,
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppTheme.gold,
                                            AppTheme.blue,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.local_cafe_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cafe.name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            cafe.categories.join(' • '),
                                            style: const TextStyle(
                                              color: AppTheme.lightGray,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 18,
                                                color: AppTheme.gold,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(cafe.rating.toString()),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        favoriteService.removeFavorite(cafe.id);
                                      },
                                      icon: const Icon(
                                        Icons.favorite_rounded,
                                        color: AppTheme.gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = favoriteService.userId;

    if (kIsWeb || userId.isEmpty) {
      return buildWebPlaceholder();
    }

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Favorit',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('favorites')
                      .where('userId', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, favoriteSnapshot) {
                    if (!favoriteSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.gold,
                        ),
                      );
                    }

                    final favoriteDocs = favoriteSnapshot.data!.docs;
                    final favoriteCafeIds = favoriteDocs
                        .map((doc) => doc['cafeId'].toString())
                        .toList();

                    if (favoriteCafeIds.isEmpty) {
                      return const Center(
                        child: Text('Belum ada kafe favorit'),
                      );
                    }

                    return StreamBuilder<List<CafeModel>>(
                      stream: cafeService.getCafes(),
                      builder: (context, cafeSnapshot) {
                        if (!cafeSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.gold,
                            ),
                          );
                        }

                        final cafes = cafeSnapshot.data!
                            .where((cafe) => favoriteCafeIds.contains(cafe.id))
                            .toList();

                        return ListView.builder(
                          itemCount: cafes.length,
                          itemBuilder: (context, index) {
                            final cafe = cafes[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.cafeDetail,
                                  arguments: cafe,
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppTheme.gold,
                                            AppTheme.blue,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.local_cafe_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cafe.name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            cafe.categories.join(' • '),
                                            style: const TextStyle(
                                              color: AppTheme.lightGray,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 18,
                                                color: AppTheme.gold,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(cafe.rating.toString()),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        favoriteService.removeFavorite(cafe.id);
                                      },
                                      icon: const Icon(
                                        Icons.favorite_rounded,
                                        color: AppTheme.gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
