import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/app_theme.dart';
import '../../utils/categories.dart';
import '../../utils/cities.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import 'category_providers_screen.dart';
import 'notifications_screen.dart';
import '../../l10n/app_localizations.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? _selectedCity;
  bool _isDetectingCity = true;
  bool _locationFailed = false;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure widget is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCity();
    });
  }

  Future<void> _initializeCity() async {
    try {
      // Step 1: Initialize notifications first (this requests notification permission)
      print('📱 Step 1: Initializing notifications...');
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await notificationService.initialize();
      print('✅ Notification permission handled');

      // Wait for notification dialog to fully dismiss before proceeding
      // Android needs more time to dismiss the permission dialog
      // Increase delay to 2 seconds to ensure the dialog is fully dismissed
      await Future.delayed(const Duration(seconds: 2));
      print('⏰ Waited 2 seconds after notification permission');

      // Step 2: Request location permission explicitly
      print('📍 Step 2: Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        // Add another delay before showing location permission dialog
        await Future.delayed(const Duration(seconds: 1));
        print('⏰ Waited 1 second before requesting location permission');

        print('📍 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('📍 Location permission result: $permission');
      } else if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permission permanently denied');
        if (mounted) {
          setState(() {
            _isDetectingCity = false;
            _locationFailed = true;
          });
          _showCitySelectionDialog();
        }
        return;
      }

      // Small delay after location permission dialog
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 3: Try to detect city if permission granted
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        print('🌍 Step 3: Detecting city...');
        final detectedCity = await _locationService.detectCurrentCity().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('⚠️ Location detection timed out');
            return SaudiCities.getCityNamesEnglish().first; // Default to Riyadh
          },
        );

        if (mounted) {
          setState(() {
            _selectedCity = detectedCity;
            _isDetectingCity = false;
            _locationFailed = false;
          });
        }
      } else {
        // Location permission denied - show city selection dialog
        print('⚠️ Location permission denied, showing city selector');
        if (mounted) {
          setState(() {
            _isDetectingCity = false;
            _locationFailed = true;
          });
          _showCitySelectionDialog();
        }
      }
    } catch (e) {
      print('❌ Error during initialization: $e');
      if (mounted) {
        setState(() {
          _isDetectingCity = false;
          _locationFailed = true;
        });
        // Show city selection dialog
        _showCitySelectionDialog();
      }
    }
  }

  Future<void> _showCitySelectionDialog() async {
    final l10n = AppLocalizations.of(context);
    final cities = SaudiCities.getCityNamesEnglish();

    final selectedCity = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.secondaryCoral),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.selectCity)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              return ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(city),
                onTap: () => Navigator.pop(context, city),
              );
            },
          ),
        ),
      ),
    );

    if (selectedCity != null && mounted) {
      setState(() {
        _selectedCity = selectedCity;
        _locationFailed = false;
      });
    } else if (_selectedCity == null && mounted) {
      // If user dismisses without selecting, default to Riyadh
      setState(() {
        _selectedCity = cities.first;
        _locationFailed = false;
      });
    }
  }

  void _onCityChanged(String? newCity) {
    if (newCity != null && newCity != _selectedCity) {
      setState(() {
        _selectedCity = newCity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(l10n.appName),
        centerTitle: true,
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (notificationService.unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryCoral,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            notificationService.unreadCount > 99
                                ? '99+'
                                : '${notificationService.unreadCount}',
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
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header
              Text(
                l10n.categories,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.allCategories,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // City Selector
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppTheme.secondaryCoral,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isDetectingCity
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryNavy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.loading,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : DropdownButton<String>(
                                value: _selectedCity,
                                isExpanded: true,
                                underline: Container(),
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppTheme.primaryNavy,
                                ),
                                style: TextStyle(
                                  color: AppTheme.primaryNavy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                items: SaudiCities.getCityNamesEnglish().map((city) {
                                  return DropdownMenuItem<String>(
                                    value: city,
                                    child: Text(city),
                                  );
                                }).toList(),
                                onChanged: _onCityChanged,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Categories
              Expanded(
                child: ListView(
                  children: [
                    // Venues & Halls
                    _CategoryCard(
                      title: 'Venues & Halls',
                      titleAr: 'قاعات و مناسبات',
                      description: 'Wedding halls, conference venues, event spaces',
                      icon: Icons.business,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryNavy,
                          AppTheme.accentBlue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        if (_selectedCity == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.pleaseSelectAddress),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryProvidersScreen(
                              category: EventCategories.venuesHallsId,
                              categoryName: EventCategories.venuesHalls.name,
                              categoryNameAr: EventCategories.venuesHalls.nameAr,
                              selectedCity: _selectedCity!,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Camping & Parties
                    _CategoryCard(
                      title: 'Camping, Parties & Celebrations',
                      titleAr: 'مخيمات, حفلات و احتفالات',
                      description: 'Camping equipment, party decorations, celebration services',
                      icon: Icons.celebration,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.secondaryCoral,
                          Colors.deepOrange,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        if (_selectedCity == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.pleaseSelectAddress),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryProvidersScreen(
                              category: EventCategories.campingPartiesId,
                              categoryName: EventCategories.campingParties.name,
                              categoryNameAr: EventCategories.campingParties.nameAr,
                              selectedCity: _selectedCity!,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Funeral Services
                    _CategoryCard(
                      title: 'Funeral Services',
                      titleAr: 'خدمات الجنائز',
                      description: 'Funeral arrangements, memorial services, support',
                      icon: Icons.local_florist,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueGrey[700]!,
                          Colors.blueGrey[500]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        if (_selectedCity == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.pleaseSelectAddress),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryProvidersScreen(
                              category: EventCategories.funeralsId,
                              categoryName: EventCategories.funerals.name,
                              categoryNameAr: EventCategories.funerals.nameAr,
                              selectedCity: _selectedCity!,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String titleAr;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.titleAr,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final displayTitle = isArabic ? titleAr : title;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayTitle,
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
