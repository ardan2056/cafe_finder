import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../models/cafe_model.dart';
import '../../services/cafe_service.dart';
import 'package:shimmer/shimmer.dart';
import '../favorite/favorite_screen.dart';
import '../maps/maps_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> pages = [
    HomeContent(),
    const SearchScreen(),
    const MapsScreen(),
    FavoriteScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      // Use IndexedStack to keep each tab's state alive when switching.
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() => currentIndex = index);
            },
            backgroundColor: Colors.transparent,
            selectedItemColor: AppTheme.gold,
            unselectedItemColor: AppTheme.gray,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_rounded),
                label: 'Maps',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded),
                label: 'Favorite',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final CafeService cafeService = CafeService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header(),
            const SizedBox(height: 18),
            searchBar(context),
            const SizedBox(height: 20),
            // Featured carousel
            sectionTitle('Pilihan Teratas'),
            const SizedBox(height: 12),
            StreamBuilder<List<CafeModel>>(
              stream: cafeService.getCafes(),
              builder: (context, snapshot) {
                final cafes = snapshot.data ?? [];
                if (cafes.isEmpty) {
                  return const SizedBox.shrink();
                }

                final featured = cafes
                    .where((c) {
                      if (_selectedCategory != null) {
                        return c.categories.contains(_selectedCategory);
                      }
                      return true;
                    })
                    .take(5)
                    .toList();

                return SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: featured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final cafe = featured[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/cafe-detail',
                            arguments: cafe,
                          );
                        },
                        child: Container(
                          width: 260,
                          decoration: AppTheme.cardDecoration(radius: 18),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _buildThumbnail(cafe),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(cafe.name,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(cafe.categories.join(' • '),
                                        style: const TextStyle(
                                            color: AppTheme.lightGray,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            sectionTitle('Kategori'),
            const SizedBox(height: 12),
            categoryList(),
            const SizedBox(height: 28),
            sectionTitle('Rekomendasi Untukmu'),
            const SizedBox(height: 18),
            StreamBuilder<List<CafeModel>>(
              stream: cafeService.getCafes(),
              builder: (context, snapshot) {
                // avoid persistent spinner: use empty list until data arrives
                var cafes = snapshot.data ?? [];

                // apply category filter
                if (_selectedCategory != null) {
                  cafes = cafes
                      .where((c) => c.categories.contains(_selectedCategory))
                      .toList();
                }

                // apply search query
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  cafes = cafes.where((c) {
                    return c.name.toLowerCase().contains(q) ||
                        c.description.toLowerCase().contains(q) ||
                        c.categories.join(' ').toLowerCase().contains(q);
                  }).toList();
                }

                if (cafes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Tidak ada kafe yang cocok.'),
                  );
                }

                return Column(
                  children: cafes.map((cafe) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/cafe-detail',
                            arguments: cafe,
                          );
                        },
                        child: cafeCard(cafe),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang 👋',
              style: TextStyle(color: AppTheme.lightGray),
            ),
            SizedBox(height: 4),
            Text(
              'Temukan Kafe Favoritmu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.map);
              },
              icon: const Icon(Icons.map_rounded),
              color: AppTheme.gold,
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget searchBar(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppTheme.gray),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Cari kafe, fasilitas, atau suasana...',
                hintStyle: TextStyle(color: AppTheme.gray),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
              },
              icon: const Icon(Icons.close_rounded, color: AppTheme.gray),
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SearchScreen(initialQuery: _searchQuery)),
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.gray),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget categoryList() {
    final categories = ['Belajar', 'Kerja', 'Nongkrong', 'Healing', 'Kreatif'];
    final all = ['Semua', ...categories];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = all[index];
          final selected = (name == 'Semua' && _selectedCategory == null) ||
              _selectedCategory == name;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) {
              setState(() {
                if (name == 'Semua') {
                  _selectedCategory = null;
                } else {
                  _selectedCategory = selected ? null : name;
                }
              });
            },
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            selectedColor: AppTheme.gold,
            label: Text(
              name,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          );
        },
      ),
    );
  }

  Widget _buildThumbnail(CafeModel cafe) {
    final image = cafe.images.isNotEmpty ? cafe.images.first : null;
    if (image != null && image.isNotEmpty) {
      return Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade800,
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.network(
          image,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade800,
              highlightColor: Colors.grey.shade600,
              child: Container(
                width: 84,
                height: 84,
                color: Colors.grey.shade800,
              ),
            );
          },
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.local_cafe_rounded, color: Colors.white),
          ),
        ),
      );
    }

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade800,
      ),
      child: const Center(
        child: Icon(Icons.local_cafe_rounded, color: Colors.white, size: 34),
      ),
    );
  }

  Widget cafeCard(CafeModel cafe) {
    return Container(
      decoration: AppTheme.cardDecoration(radius: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              gradient: LinearGradient(
                colors: [
                  AppTheme.gold.withValues(alpha: 0.75),
                  AppTheme.blue.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Builder(builder: (context) {
              if (cafe.images.isNotEmpty) {
                return ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Image.network(
                    cafe.images.first,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.gold),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.local_cafe_rounded,
                          size: 52, color: Colors.white),
                    ),
                  ),
                );
              }

              return const Center(
                child: Icon(
                  Icons.local_cafe_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppTheme.gold,
                          size: 18,
                        ),
                        Text(cafe.rating.toString()),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  cafe.categories.join(' • '),
                  style: const TextStyle(color: AppTheme.lightGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
