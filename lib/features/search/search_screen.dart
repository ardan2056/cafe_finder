import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cafe_model.dart';
import '../../services/cafe_service.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final CafeService cafeService = CafeService();
  final TextEditingController searchController = TextEditingController();

  String keyword = '';
  String selectedCategory = 'Semua';

  final List<String> categories = [
    'Semua',
    'Belajar',
    'Kerja',
    'Nongkrong',
    'Meeting',
    'Kreatif',
    'Healing',
  ];

  List<CafeModel> filterCafes(List<CafeModel> cafes) {
    return cafes.where((cafe) {
      final lowerKeyword = keyword.toLowerCase();

      final matchKeyword = cafe.name.toLowerCase().contains(lowerKeyword) ||
          cafe.address.toLowerCase().contains(lowerKeyword) ||
          cafe.facilities.any(
            (item) => item.toLowerCase().contains(lowerKeyword),
          ) ||
          cafe.atmosphere.any(
            (item) => item.toLowerCase().contains(lowerKeyword),
          );

      final matchCategory = selectedCategory == 'Semua' ||
          cafe.categories.contains(selectedCategory);

      return matchKeyword && matchCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // initialize controller from widget.initialQuery if provided
    if (widget.initialQuery != null &&
        widget.initialQuery!.isNotEmpty &&
        searchController.text.isEmpty) {
      searchController.text = widget.initialQuery!;
      keyword = widget.initialQuery!;
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
                'Cari Kafe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() => keyword = value);
                },
                decoration: InputDecoration(
                  hintText: 'Cari kafe, fasilitas, atau suasana...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final selected = selectedCategory == category;

                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedCategory = category);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.gold
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<CafeModel>>(
                  stream: cafeService.getCafes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.gold,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Gagal memuat data kafe'),
                      );
                    }

                    final cafes = filterCafes(snapshot.data ?? []);

                    if (cafes.isEmpty) {
                      return const Center(
                        child: Text('Kafe tidak ditemukan'),
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
                            decoration: AppTheme.cardDecoration(radius: 22),
                            child: Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: Colors.grey.shade800,
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: cafe.images.isNotEmpty
                                      ? Image.network(
                                          cafe.images.first,
                                          fit: BoxFit.cover,
                                          width: 72,
                                          height: 72,
                                          loadingBuilder:
                                              (context, child, progress) {
                                            if (progress == null) return child;
                                            return Shimmer.fromColors(
                                              baseColor: Colors.grey.shade800,
                                              highlightColor:
                                                  Colors.grey.shade600,
                                              child: Container(
                                                  color: Colors.grey.shade800),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) =>
                                              const Center(
                                            child: Icon(
                                                Icons.local_cafe_rounded,
                                                color: Colors.white,
                                                size: 34),
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.local_cafe_rounded,
                                            color: Colors.white,
                                            size: 34,
                                          ),
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
                              ],
                            ),
                          ),
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
