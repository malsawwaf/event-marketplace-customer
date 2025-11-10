import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Icon(
              Icons.event,
              size: 100,
              color: Colors.blue[700],
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'Event Marketplace',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customer App',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
          ],
        ),
      ),
    );
  }
}