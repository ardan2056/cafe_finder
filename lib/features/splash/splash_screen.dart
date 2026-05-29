import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/firebase_status.dart' as fb_status;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    fadeAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeIn,
    );

    scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );

    controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // If Firebase failed to initialize, show a prominent SnackBar on the onboarding route.
        if (fb_status.firebaseInitError != null) {
          // pass along by navigating and showing a banner
          Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = context;
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content:
                  Text('Firebase init error: ${fb_status.firebaseInitError}'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 6),
            ));
          });
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 105,
                      height: 105,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.gold.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gold.withValues(alpha: 0.45),
                            blurRadius: 45,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_cafe_rounded,
                        color: AppTheme.gold,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Cafe Finder',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Find Your Perfect Space',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.lightGray,
                      ),
                    ),
                    const SizedBox(height: 36),
                    const SizedBox(
                      width: 160,
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        color: AppTheme.gold,
                        backgroundColor: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const spacing = 36.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
