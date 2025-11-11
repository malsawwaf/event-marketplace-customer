import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
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
    // Wait for 2 seconds to show splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Check authentication status
    if (authProvider.isAuthenticated) {
      // Check if profile is completed
      final hasProfile = await authProvider.checkProfileCompletion();
      
      if (!mounted) return;

      if (hasProfile) {
        // ✅ FIXED: Navigate to home with global key
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BottomNavScreen(key: bottomNavKey), // ✅ Added key
          ),
        );
      } else {
        // Navigate to profile completion (you'll create this)
        Navigator.of(context).pushReplacementNamed('/complete-profile');
      }
    } else {
      // Navigate to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryNavy,
              AppTheme.accentBlue,
              AppTheme.primaryNavy.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // App Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if logo doesn't load
                      return Icon(
                        Icons.celebration,
                        size: 120,
                        color: AppTheme.secondaryCoral,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // App Name
                const Text(
                  'Event Marketplace',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Discover & Book Amazing Events',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const Spacer(flex: 2),

                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),

                const SizedBox(height: 16),

                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(flex: 1),

                // Powered by
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Powered by Azimah Tech',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
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