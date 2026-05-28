import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();
  int currentIndex = 0;

  final List<Map<String, dynamic>> pages = [
    {
      'icon': Icons.local_cafe_rounded,
      'title': 'Temukan Kafe Sesuai Aktivitasmu',
      'desc':
          'Cari kafe untuk belajar, bekerja, nongkrong, meeting, atau kegiatan kreatif sesuai kebutuhanmu.',
    },
    {
      'icon': Icons.map_rounded,
      'title': 'Smart Mapping',
      'desc':
          'Temukan kafe berdasarkan lokasi, fasilitas, suasana, rating, dan preferensi pengguna.',
    },
    {
      'icon': Icons.groups_rounded,
      'title': 'Ruang Sosial Modern',
      'desc':
          'Bangun pengalaman sosial melalui rekomendasi kafe yang mendukung interaksi dan komunitas.',
    },
  ];

  void nextPage() {
    if (currentIndex == pages.length - 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: skip,
                child: const Text(
                  'Lewati',
                  style: TextStyle(color: AppTheme.lightGray),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.gold.withValues(alpha: 0.12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.gold.withValues(alpha: 0.35),
                                blurRadius: 60,
                                spreadRadius: 12,
                              ),
                            ],
                          ),
                          child: Icon(
                            page['icon'],
                            size: 86,
                            color: AppTheme.gold,
                          ),
                        ),
                        const SizedBox(height: 42),
                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          page['desc'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.lightGray,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) {
                  final isActive = currentIndex == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: isActive ? 28 : 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.gold : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 34),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    currentIndex == pages.length - 1
                        ? 'Mulai Sekarang'
                        : 'Lanjut',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
