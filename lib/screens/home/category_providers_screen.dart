import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../services/provider_service.dart';
import '../../utils/cities.dart';
import '../../widgets/provider_card_widget.dart';
import 'provider_detail_screen.dart';

class CategoryProvidersScreen extends StatefulWidget {
  final String category;
  final String categoryName;
  final String selectedCity;

  const CategoryProvidersScreen({
    Key? key,
    required this.category,
    required this.categoryName,
    required this.selectedCity,
  }) : super(key: key);

  @override
  State<CategoryProvidersScreen> createState() => _CategoryProvidersScreenState();
}

class _CategoryProvidersScreenState extends State<CategoryProvidersScreen> {
  final _supabase = Supabase.instance.client;
  final ProviderService _providerService = ProviderService();

  List<Map<String, dynamic>> _featuredProviders = [];
  List<Map<String, dynamic>> _allProviders = [];
  bool _isLoading = true;
  String _sortBy = 'rating'; // rating, price_range, name_asc, name_desc

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load featured providers
      final featured = await _providerService.getProviders(
        category: widget.category,
        city: widget.selectedCity,
        country: SaudiCities.defaultCountry,
        isFeatured: true,
      );

      // Load all providers sorted by rating
      final all = await _providerService.getProviders(
        category: widget.category,
        city: widget.selectedCity,
        country: SaudiCities.defaultCountry,
      );

      setState(() {
        _featuredProviders = featured;
        _allProviders = all;
        _sortProviders();
        _isLoading = false;
      });

      print('🔵 Loaded ${featured.length} featured and ${all.length} total providers for ${widget.categoryName} in ${widget.selectedCity}');
    } catch (e) {
      print('❌ Error loading providers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortProviders() {
    switch (_sortBy) {
      case 'rating':
        _allProviders.sort((a, b) {
          final ratingA = (a['average_rating'] as num?)?.toDouble() ?? 0.0;
          final ratingB = (b['average_rating'] as num?)?.toDouble() ?? 0.0;
          return ratingB.compareTo(ratingA); // Highest first
        });
        break;
      case 'price_range':
        _allProviders.sort((a, b) {
          final priceA = _getPriceRangeValue(a['price_range'] as String? ?? 'moderate');
          final priceB = _getPriceRangeValue(b['price_range'] as String? ?? 'moderate');
          return priceA.compareTo(priceB); // Lowest first
        });
        break;
      case 'name_asc':
        _allProviders.sort((a, b) {
          final nameA = (a['company_name_en'] as String? ?? '').toLowerCase();
          final nameB = (b['company_name_en'] as String? ?? '').toLowerCase();
          return nameA.compareTo(nameB); // A-Z
        });
        break;
      case 'name_desc':
        _allProviders.sort((a, b) {
          final nameA = (a['company_name_en'] as String? ?? '').toLowerCase();
          final nameB = (b['company_name_en'] as String? ?? '').toLowerCase();
          return nameB.compareTo(nameA); // Z-A
        });
        break;
    }
  }

  int _getPriceRangeValue(String priceRange) {
    switch (priceRange.toLowerCase()) {
      case 'budget':
        return 1;
      case 'moderate':
        return 2;
      case 'premium':
        return 3;
      case 'luxury':
        return 4;
      default:
        return 2;
    }
  }

  void _onSortChanged(String? newSort) {
    if (newSort != null && newSort != _sortBy) {
      setState(() {
        _sortBy = newSort;
        _sortProviders();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // City Display (Read-only)
          Container(
            color: AppTheme.primaryNavy,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: AppTheme.secondaryCoral,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.selectedCity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Change city from home screen',
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          // Providers List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _allProviders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No providers found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'in ${widget.selectedCity} for ${widget.categoryName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: () {
                                // Navigate back to home screen to change city
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Change city from the home screen'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Change City'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryNavy,
                                side: BorderSide(color: AppTheme.primaryNavy),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProviders,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Featured Providers Section (Horizontal Scroll)
                              if (_featuredProviders.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: AppTheme.secondaryCoral,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Featured Providers',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _featuredProviders.length,
                                    itemBuilder: (context, index) {
                                      final provider = _featuredProviders[index];
                                      return Container(
                                        width: 300,
                                        margin: const EdgeInsets.only(right: 16),
                                        child: ProviderCardWidget(
                                          provider: provider,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ProviderDetailScreen(
                                                  providerId: provider['id'] as String,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // All Providers Section (Vertical List)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Text(
                                  'All Providers',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Text(
                                      'Sort by:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: DropdownButton<String>(
                                          value: _sortBy,
                                          isExpanded: true,
                                          underline: Container(),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down,
                                            color: AppTheme.primaryNavy,
                                            size: 20,
                                          ),
                                          style: TextStyle(
                                            color: AppTheme.primaryNavy,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'rating',
                                              child: Text('Highest Rating'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'price_range',
                                              child: Text('Price Range'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'name_asc',
                                              child: Text('Name (A-Z)'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'name_desc',
                                              child: Text('Name (Z-A)'),
                                            ),
                                          ],
                                          onChanged: _onSortChanged,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _allProviders.length,
                                itemBuilder: (context, index) {
                                  final provider = _allProviders[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: ProviderCardWidget(
                                      provider: provider,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProviderDetailScreen(
                                              providerId: provider['id'] as String,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
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
