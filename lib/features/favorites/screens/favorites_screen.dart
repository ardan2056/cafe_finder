import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/cafe_card.dart';
import '../../../providers/cafe_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cafeProvider = context.watch<CafeProvider>();
    final favorites = cafeProvider.favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Cafes')),
      body: favorites.isEmpty
          ? const Center(child: Text('Belum ada cafe favorit'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final cafe = favorites[index];
                return CafeCard(
                  cafe: cafe,
                  isFavorite: true,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.cafeDetail, arguments: cafe),
                  onFavoriteTap: () => context.read<CafeProvider>().toggleFavorite(cafe.id),
                );
              },
            ),
    );
  }
}
