import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../services/provider_service.dart';
import '../../services/favourites_service.dart';
import '../../services/items_service.dart';
import '../../services/reviews_service.dart';
import '../../utils/categories.dart';
import '../../widgets/item_card.dart';
import '../../widgets/review_card.dart';
import '../../l10n/app_localizations.dart';

class ProviderDetailScreen extends StatefulWidget {
  final String providerId;

  const ProviderDetailScreen({
    Key? key,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  final _supabase = Supabase.instance.client;
  final ProviderService _providerService = ProviderService();
  final FavoritesService _favoritesService = FavoritesService();
  final ItemsService _itemsService = ItemsService();
  final ReviewsService _reviewsService = ReviewsService();

  Map<String, dynamic>? _provider;
  Map<String, List<Map<String, dynamic>>> _groupedItems = {};
  List<Map<String, dynamic>> _recentReviews = [];
  bool _isFavorite = false;
  bool _isLoading = true;
  String? _selectedCategory;
  final Map<String, GlobalKey> _categoryKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProviderDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customerId = _supabase.auth.currentUser?.id;
      
      final provider = await _providerService.getProviderById(widget.providerId);
      final isFav = customerId != null
          ? await _favoritesService.isProviderFavorited(customerId, widget.providerId)
          : false;
      final items = await _itemsService.fetchItemsByProvider(widget.providerId);
      final reviews = await _reviewsService.getRecentReviews(widget.providerId);

      // Create global keys for each category
      for (var category in items.keys) {
        _categoryKeys[category] = GlobalKey();
      }

      setState(() {
        _provider = provider;
        _isFavorite = isFav;
        _groupedItems = items;
        _recentReviews = reviews;
        _isLoading = false;
        _selectedCategory = items.keys.isNotEmpty ? items.keys.first : null;
      });
    } catch (e) {
      print('Error loading provider details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });

    // Wait for setState to complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _categoryKeys[category];
      if (key?.currentContext != null) {
        final RenderBox box = key!.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject()).dy;
        final scrollPosition = _scrollController.position.pixels + position - 100; // Offset for app bar

        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _toggleFavorite() async {
    final l10n = AppLocalizations.of(context);
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginFailed)),
      );
      return;
    }

    try {
      final newStatus = await _favoritesService.toggleProviderFavorite(
        customerId,
        widget.providerId,
      );

      setState(() {
        _isFavorite = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? l10n.addToFavorites : l10n.removeFromFavorites,
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryNavy,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_provider == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryNavy,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(l10n.noProviders),
        ),
      );
    }

    final businessName = isArabic && _provider!['company_name_ar'] != null
        ? _provider!['company_name_ar']
        : _provider!['company_name_en'] ?? 'Unknown Business';
    final category = _provider!['category'] ?? '';
    final categoryInfo = EventCategories.getById(category);
    final description = _provider!['store_description'] ?? 'No description available';
    final rating = (_provider!['average_rating'] ?? 0.0).toDouble();
    final reviewCount = _provider!['total_reviews'] ?? 0;
    final city = _provider!['city'] ?? '';
    final country = _provider!['country'] ?? '';
    final address = _provider!['store_address'] ?? '';
    final priceRange = _provider!['price_range'] ?? '';
    final coverImage = _provider!['profile_photo_url'];

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar with Cover Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppTheme.primaryNavy,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: coverImage != null
                  ? Image.network(
                      coverImage,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(
                        categoryInfo?.icon ?? Icons.business,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Name & Category
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              businessName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            ),
                          ),
                          if (categoryInfo != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: categoryInfo.color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    categoryInfo.icon,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    categoryInfo.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Rating & Reviews
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[700], size: 24),
                          const SizedBox(width: 6),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($reviewCount ${l10n.reviews})',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Location (City only)
                      if (city.isNotEmpty)
                        _buildInfoRow(
                          Icons.location_on,
                          '$city${country.isNotEmpty ? ", $country" : ""}',
                        ),
                      // Price Range with SAR Icon
                      if (priceRange.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              _buildPriceRangeIcons(priceRange),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Description
                      Text(
                        l10n.about,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Services & Packages Section
                _buildServicesSection(),
                // Reviews Section
                _buildReviewsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeIcons(String priceRange) {
    int activeCount = 1;
    switch (priceRange.toLowerCase()) {
      case 'budget':
        activeCount = 1;
        break;
      case 'moderate':
        activeCount = 2;
        break;
      case 'premium':
        activeCount = 3;
        break;
      case 'luxury':
        activeCount = 4;
        break;
    }

    return Row(
      children: List.generate(4, (index) {
        final isActive = index < activeCount;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Image.asset(
            'assets/icons/sar_icon.png',
            width: 20,
            height: 20,
            color: isActive ? Colors.green[700] : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Filter Bar
          if (_groupedItems.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _groupedItems.keys.length,
                itemBuilder: (context, index) {
                  final category = _groupedItems.keys.elementAt(index);
                  final isSelected = category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _scrollToCategory(category),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryNavy
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryNavy
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.primaryNavy,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          _groupedItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No services available yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Column(
                  children: _groupedItems.entries.map((entry) {
                    final category = entry.key;
                    final items = entry.value;

                    return Container(
                      key: _categoryKeys[category],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey[300], thickness: 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey[300], thickness: 1),
                              ),
                            ],
                          ),
                        ),
                          // Items in this category
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: items.map((item) => ItemCard(item: item)).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rate_review, size: 24),
              SizedBox(width: 8),
              Text(
                'Recent Reviews',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _recentReviews.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryNavy.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: AppTheme.primaryNavy.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Be the first to review!',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.primaryNavy,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentReviews.length,
                    itemBuilder: (context, index) {
                      return ReviewCard(review: _recentReviews[index]);
                    },
                  ),
                ),
        ],
      ),
    );
  }
}