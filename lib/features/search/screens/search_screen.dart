import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/cafe_card.dart';
import '../../../providers/cafe_provider.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cafeProvider = context.watch<CafeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Search Cafes')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              onChanged: cafeProvider.updateSearch,
              decoration: const InputDecoration(
                hintText: 'Search by name, location, or vibe',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: cafeProvider.cafes.isEmpty
                  ? const Center(child: Text('No cafe found'))
                  : ListView.separated(
                      itemCount: cafeProvider.cafes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final cafe = cafeProvider.cafes[index];
                        return CafeCard(
                          cafe: cafe,
                          isFavorite: cafeProvider.isFavorite(cafe.id),
                          onTap: () => Navigator.pushNamed(context, AppRoutes.cafeDetail, arguments: cafe),
                          onFavoriteTap: () => context.read<CafeProvider>().toggleFavorite(cafe.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
