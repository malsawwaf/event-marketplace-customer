import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../l10n/app_localizations.dart';
import 'categories_screen.dart';
import 'cart_screen.dart';
import 'orders_list_screen.dart';
import 'favourites_screen.dart';
import 'profile_screen.dart';
import '../../services/cart_service.dart';

// ✅ NEW: Global key to access BottomNavScreen from anywhere
final GlobalKey<_BottomNavScreenState> bottomNavKey = GlobalKey<_BottomNavScreenState>();

class BottomNavScreen extends StatefulWidget {
  final int initialIndex;
  
  const BottomNavScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  final _supabase = Supabase.instance.client;
  late int _selectedIndex;
  int _cartItemCount = 0;
  Timer? _cartCountTimer;
  
  // Create navigators for each tab to maintain state
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadCartCount();
    // Refresh cart count every 30 seconds
    _cartCountTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadCartCount(),
    );
  }

  @override
  void dispose() {
    _cartCountTimer?.cancel();
    super.dispose();
  }

  // ✅ NEW: Public method to switch tabs from outside
  void switchToTab(int index) {
    if (mounted && index >= 0 && index < 5) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _loadCartCount() async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) {
      if (mounted) {
        setState(() => _cartItemCount = 0);
      }
      return;
    }

    final cartService = CartService();
    try {
      final count = await cartService.getCartItemCount(customerId);
      if (mounted) {
        setState(() => _cartItemCount = count);
      }
    } catch (e) {
      print('Error loading cart count: $e');
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // If tapping the same tab, pop to root of that tab's navigator
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }

    // Refresh cart count when switching to cart tab
    if (index == 1) {
      _loadCartCount();
    }
  }

  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button - pop current tab's navigator
        final currentNavigator = _navigatorKeys[_selectedIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildNavigator(0, const CategoriesScreen()),
            _buildNavigator(1, const CartScreen()),
            _buildNavigator(2, const OrdersListScreen()),
            _buildNavigator(3, const FavoritesScreen()),
            _buildNavigator(4, const ProfileScreen()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: AppLocalizations.of(context).home,
            ),
            BottomNavigationBarItem(
              icon: _buildCartIcon(),
              label: AppLocalizations.of(context).cart,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: AppLocalizations.of(context).orders,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: AppLocalizations.of(context).favorites,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: AppLocalizations.of(context).profile,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCartIcon() {
    if (_cartItemCount == 0) {
      return const Icon(Icons.shopping_cart);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart),
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Text(
              _cartItemCount > 99 ? '99+' : '$_cartItemCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}