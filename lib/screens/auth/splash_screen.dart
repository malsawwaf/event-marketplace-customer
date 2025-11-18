import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/language_service.dart';
import '../../l10n/app_localizations.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
import 'profile_completion_screen.dart';
import '../home/bottom_nav_screen.dart'; // ✅ This import gives us access to bottomNavKey

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      // Wait for 2 seconds to show splash
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      print('🔵 Splash: Starting navigation check...');

      final authProvider = context.read<AuthProvider>();
      print('🔵 Splash: Auth provider loaded, isAuthenticated: ${authProvider.isAuthenticated}');

      // Check authentication status
      if (authProvider.isAuthenticated) {
        print('🔵 Splash: User is authenticated, checking profile...');
        // Check if profile is completed
        final hasProfile = await authProvider.checkProfileCompletion();

        if (!mounted) return;

        print('🔵 Splash: Profile check result: $hasProfile');

        if (hasProfile) {
          print('🔵 Splash: Navigating to home...');
          // ✅ FIXED: Navigate to home with global key
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BottomNavScreen(key: bottomNavKey), // ✅ Added key
            ),
          );
        } else {
          print('🔵 Splash: Navigating to profile completion...');
          // Navigate to profile completion
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ProfileCompletionScreen()),
          );
        }
      } else {
        print('🔵 Splash: User not authenticated, navigating to login...');
        // Navigate to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Splash: Error during navigation: $e');
      print('❌ Stack trace: $stackTrace');

      // Fallback: navigate to login on error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.secondaryCoral,
              AppTheme.secondaryCoral.withOpacity(0.8),
              const Color(0xFFFF8A6A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ========================================
                // LOGO EDGE EFFECT OPTIONS
                // Uncomment ONE option at a time to test
                // ========================================

                // OPTION 1: Soft Glow/Shadow Effect
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 280,
                    height: 280,
                  ),
                ),

//                 OPTION 2: Circular Gradient Fade
//                 Container(
//                   width: 280,
//                   height: 280,
//                   decoration: BoxDecoration(
//                     gradient: RadialGradient(
//                       colors: [
//                         Colors.transparent,
//                         AppTheme.secondaryCoral.withOpacity(0.3),
//                       ],
//                       stops: const [0.7, 1.0],
//                     ),
//                   ),
//                   child: Image.asset(
//                     'assets/images/logo.png',
//                     width: 280,
//                     height: 280,
//                   ),
//                 ),

//               OPTION 3: Rounded Container with Blur
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(40),
//                   child: Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.1),
//                     ),
//                     child: Image.asset(
//                       'assets/images/logo.png',
//                       width: 280,
//                       height: 280,
//                     ),
//                   ),
//                 ),

                // OPTION 4: Subtle Drop Shadow
                // Container(
                //   decoration: BoxDecoration(
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withOpacity(0.2),
                //         blurRadius: 30,
                //         offset: const Offset(0, 15),
                //       ),
                //     ],
                //   ),
                //   child: Image.asset(
                //     'assets/images/logo.png',
                //     width: 280,
                //     height: 280,
                //   ),
                // ),

                // OPTION 5: No Effect (Keep Clean)
                // Image.asset(
                //   'assets/images/logo.png',
                //   width: 280,
                //   height: 280,
                // ),

                const Spacer(flex: 2),

                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),

                const SizedBox(height: 16),

                Text(
                  AppLocalizations.of(context).loading,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(flex: 1),

                // Powered by
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    '© 2025 Althawra Altakniya & Azimah Tech - All Rights Reserved',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
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