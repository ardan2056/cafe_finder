import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/admin/admin_login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/cafe_detail/cafe_detail_screen.dart';
import 'features/maps/maps_screen.dart';
import 'features/stitch/stitch_explorer_screen.dart';
import 'features/events/community_detail_screen.dart';
import 'features/events/group_chat_screen.dart';

class CafeFinderApp extends StatelessWidget {
  const CafeFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Cafe Finder',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (context) => const SplashScreen(),
            AppRoutes.onboarding: (context) => const OnboardingScreen(),
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.register: (context) => const RegisterScreen(),
            AppRoutes.adminLogin: (context) => const AdminLoginScreen(),
            AppRoutes.home: (context) => const HomeScreen(),
            AppRoutes.cafeDetail: (context) => CafeDetailScreen(),
            AppRoutes.map: (context) => const MapsScreen(),
            AppRoutes.stitchExplorer: (context) => const StitchExplorerScreen(),
            AppRoutes.communityDetail: (context) => const CommunityDetailScreen(),
            AppRoutes.groupChat: (context) => const GroupChatScreen(),
          },
        );
      },
    );
  }
}
