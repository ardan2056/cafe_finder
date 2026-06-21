import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../models/cafe_model.dart';
import '../../services/cafe_service.dart';
import '../../services/favorite_service.dart';
import '../maps/maps_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../events/community_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final mapsKey = GlobalKey<MapsScreenState>();

  // Pages are built inside build() so we can pass callbacks that call setState.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      // Use IndexedStack to keep each tab's state alive when switching.
      body: IndexedStack(
        index: currentIndex,
        children: [
          HomeContent(
            onOpenMap: () {
              setState(() => currentIndex = 1);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  mapsKey.currentState?.centerOnUser();
                } catch (_) {}
              });
            },
            onSwitchToProfile: () {
              setState(() => currentIndex = 3);
            },
          ),
          MapsScreen(key: mapsKey),
          CommunityHubScreen(isActive: currentIndex == 2),
          ProfileScreen(isActive: currentIndex == 3),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                setState(() => currentIndex = index);
              },
              backgroundColor: Colors.transparent,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.gray.withValues(alpha: 0.7),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_rounded),
                activeIcon: Icon(Icons.explore_rounded, color: AppTheme.primary),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_rounded),
                activeIcon: Icon(Icons.map_rounded, color: AppTheme.primary),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_rounded),
                activeIcon: Icon(Icons.groups_rounded, color: AppTheme.primary),
                label: 'Events',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded),
                activeIcon: const Icon(Icons.person_rounded, color: AppTheme.primary),
                label: 'Profile',
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final VoidCallback? onOpenMap;
  final VoidCallback? onSwitchToProfile;

  const HomeContent({super.key, this.onOpenMap, this.onSwitchToProfile});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final CafeService cafeService = CafeService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedActivityName;

  @override
  void initState() {
    super.initState();

    // Pastikan state filter tidak “nyangkut” sehingga beranda
    // tidak terlihat seperti cuma menampilkan 1 cafe padahal data ada banyak.
    _selectedCategory = null;
    _selectedActivityName = null;
    _searchQuery = '';

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Bento activities list
  final List<Map<String, dynamic>> _activities = [
    {'name': 'Belajar', 'icon': Icons.menu_book_rounded, 'filter': 'Belajar'},
    {'name': 'Bekerja', 'icon': Icons.laptop_mac_rounded, 'filter': 'Kerja'},
    {'name': 'Meeting', 'icon': Icons.groups_rounded, 'filter': 'Meeting'},
    {'name': 'Nongkrong', 'icon': Icons.chat_bubble_rounded, 'filter': 'Nongkrong'},
    {'name': 'Komunitas', 'icon': Icons.hub_rounded, 'filter': 'Komunitas'},
    {'name': 'Santai', 'icon': Icons.coffee_maker_rounded, 'filter': 'Santai'},
    {'name': 'Diskusi', 'icon': Icons.forum_rounded, 'filter': 'Kerja'},
    {'name': 'Kreatif', 'icon': Icons.palette_rounded, 'filter': 'Kreatif'},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header(),
            const SizedBox(height: 20),
            
            // Welcome Section
            const PamphletCarousel(),
            const SizedBox(height: 20),

            // Search Bar
            searchBar(context),
            const SizedBox(height: 24),

            // Bento Activity Grid
            const Text(
              'Aktivitas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.1,
              ),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final act = _activities[index];
                final isSelected = _selectedActivityName == act['name'];

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedActivityName = null;
                        _selectedCategory = null;
                      } else {
                        _selectedActivityName = act['name'] as String;
                        _selectedCategory = act['filter'] as String;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.secondaryContainer.withValues(alpha: 0.6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.5)
                            : const Color(0xFFD4C3BA).withValues(alpha: 0.3),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.08)
                              : AppTheme.primary.withValues(alpha: 0.02),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.1)
                                : AppTheme.secondaryContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            act['icon'] as IconData,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            act['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Smart Match Card
            const Text(
              'Smart Match Rekomendasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<CafeModel>>(
              stream: cafeService.getCafes(),
              builder: (context, snapshot) {
                final cafes = snapshot.data ?? [];
                if (cafes.isEmpty) {
                  return Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                // Filter matching cafes
                var matches = cafes;
                if (_selectedCategory != null) {
                  matches = cafes
                      .where((c) => c.categories.contains(_selectedCategory))
                      .toList();
                }

                if (matches.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration(),
                    width: double.infinity,
                    child: Column(
                      children: [
                        const Icon(Icons.coffee_rounded, size: 48, color: AppTheme.secondary),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada kafe yang cocok',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coba pilih aktivitas lain atau reset filter.',
                          style: TextStyle(color: AppTheme.textLight.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  );
                }

                final topCafe = matches.first;

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/cafe-detail',
                      arguments: topCafe,
                    );
                  },
                  child: Container(
                    decoration: AppTheme.cardDecoration(radius: 28),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            // Main image
                            AspectRatio(
                              aspectRatio: 16 / 10,
                              child: topCafe.images.isNotEmpty
                                  ? Image.network(
                                      topCafe.images.first,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: AppTheme.secondaryContainer.withValues(alpha: 0.5),
                                      child: const Center(
                                        child: Icon(
                                          Icons.local_cafe_rounded,
                                          size: 64,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                            ),
                            // Match percentage badge
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.bolt, color: AppTheme.tertiaryContainer, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      '98% Match',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Bookmark Quick Save
                            Positioned(
                              top: 14,
                              right: 14,
                              child: StreamBuilder<bool>(
                                stream: FavoriteService().isFavorite(topCafe.id),
                                builder: (context, favSnap) {
                                  final isFav = favSnap.data ?? false;
                                  return GestureDetector(
                                    onTap: () async {
                                      if (isFav) {
                                        await FavoriteService().removeFavorite(topCafe.id);
                                      } else {
                                        await FavoriteService().addFavorite(topCafe.id);
                                      }
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      topCafe.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: AppTheme.tertiaryContainer, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        topCafe.rating.toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: AppTheme.secondary, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      topCafe.address,
                                      style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Chips
                              Wrap(
                                spacing: 8,
                                children: topCafe.facilities.take(3).map((f) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryContainer.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/cafe-detail',
                                      arguments: topCafe,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Buka Detail Cafe', style: TextStyle(fontWeight: FontWeight.bold)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Secondary Suggestions
            StreamBuilder<List<CafeModel>>(
              stream: cafeService.getCafes(),
              builder: (context, snapshot) {
                final cafes = snapshot.data ?? [];
                if (cafes.isEmpty) return const SizedBox.shrink();

                final category = _selectedCategory ?? 'Kerja';
                final matches = cafes
                    .where((c) => c.categories.contains(category))
                    .toList();

                // Skip the topCafe if it's already shown in the primary card
                if (matches.isNotEmpty) {
                  matches.removeAt(0);
                }

                if (matches.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Populer untuk \'$category\'',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final cafe = matches[index];
                          final image = cafe.images.isNotEmpty ? cafe.images.first : '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/cafe-detail',
                                arguments: cafe,
                              );
                            },
                            child: Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFD4C3BA).withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: image.isNotEmpty
                                        ? Image.network(
                                            image,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: AppTheme.secondaryContainer.withValues(alpha: 0.4),
                                            child: const Center(
                                              child: Icon(
                                                Icons.local_cafe_rounded,
                                                color: AppTheme.primary,
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cafe.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: AppTheme.tertiaryContainer,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              cafe.rating.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
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
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
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
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                // If parent provided a callback, use it to switch to the Maps tab
                // (keeps UI in a single page and preserves IndexedStack state).
                if (widget.onOpenMap != null) {
                  widget.onOpenMap!();
                } else {
                  Navigator.pushNamed(context, AppRoutes.map);
                }
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
    final categories = ['Belajar', 'Kerja', 'Nongkrong', 'Santai', 'Meeting', 'Komunitas', 'Kreatif'];
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
                  _selectedActivityName = null;
                } else {
                  if (selected) {
                    _selectedCategory = null;
                    _selectedActivityName = null;
                  } else {
                    _selectedCategory = name;
                    final matchingAct = _activities.firstWhere(
                      (a) => a['filter'] == name,
                      orElse: () => <String, dynamic>{},
                    );
                    _selectedActivityName = matchingAct.isNotEmpty ? matchingAct['name'] as String : null;
                  }
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

class PamphletCarousel extends StatefulWidget {
  const PamphletCarousel({super.key});

  @override
  State<PamphletCarousel> createState() => _PamphletCarouselState();
}

class _PamphletCarouselState extends State<PamphletCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _banners = [
    {
      'title': 'Temukan Ruang Kerja Terbaik',
      'desc': 'Kafe tenang dengan Wi-Fi kencang & colokan melimpah untuk produktivitasmu.',
      'imageUrl': 'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=800&auto=format&fit=crop&q=80',
      'tag': 'PRODUKTIF',
    },
    {
      'title': 'Ngopi Seru Bareng Komunitas',
      'desc': 'Temukan teman satu hobi dan ikuti event seru di Community Hub BrewQuest.',
      'imageUrl': 'https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=800&auto=format&fit=crop&q=80',
      'tag': 'KOMUNITAS',
    },
    {
      'title': 'Eksplorasi Cita Rasa Baru',
      'desc': 'Cari rekomendasi menu kopi unik dan artisan roaster terdekat dari posisimu.',
      'imageUrl': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&auto=format&fit=crop&q=80',
      'tag': 'CITA RASA',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: Image.network(
                        banner['imageUrl']!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Dark Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              banner['tag']!,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner['desc']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? AppTheme.primary : AppTheme.gray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

