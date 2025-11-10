// This file now just exports the BottomNavScreen
// Keep this for backwards compatibility with existing imports

export 'bottom_nav_screen.dart';

// If you want to use HomeScreen directly, it redirects to BottomNavScreen
import 'package:flutter/material.dart';
import 'bottom_nav_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BottomNavScreen();
  }
}