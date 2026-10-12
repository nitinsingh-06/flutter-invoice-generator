import 'package:flutter/material.dart';

import '../../services/hive_service.dart';
import '../company_settings/company_settings_screen.dart';
import '../home/home_screen.dart';
import '../../theme/app_theme.dart';

/// First screen shown on app launch.
///
/// Displays the company/app branding with a brief loading animation, then
/// automatically navigates onward:
/// - If no company profile has been saved yet (first-ever launch), routes
///   to [CompanySettingsScreen] so the user sets up their business details
///   before creating any invoices.
/// - Otherwise, routes straight to [HomeScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigateNext();
  }

  /// Waits for both the branding animation and a minimum splash duration
  /// (so the logo doesn't just flash on-screen on fast devices), then
  /// decides where to go based on whether Company Settings has been
  /// completed yet.
  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final company = HiveService.getCompanyProfile();
    final hasCompletedSetup = company != null && company.isProfileComplete;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => hasCompletedSetup
            ? const HomeScreen()
            : const CompanySettingsScreen(isFirstTimeSetup: true),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 52,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bill Generator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Professional Invoices, Offline',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}