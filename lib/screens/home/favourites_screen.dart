import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/favourites_service.dart';
import 'provider_detail_screen.dart';
import 'item_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _allFavorites = [];
  List<Map<String, dynamic>> _providerFavorites = [];
  List<Map<String, dynamic>> _itemFavorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    final favoritesService = FavoritesService();

    try {
      final all = await favoritesService.getAllFavorites(customerId);
      final providers = await favoritesService.getProviderFavorites(customerId);
      final items = await favoritesService.getItemFavorites(customerId);

      if (mounted) {
        setState(() {
          _allFavorites = all;
          _providerFavorites = providers;
          _itemFavorites = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorites: $e')),
        );
      }
    }
  }

  Future<void> _removeProviderFavorite(String providerId) async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites'),
        content: const Text('Remove this provider from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final favoritesService = FavoritesService();

    try {
      await favoritesService.removeProviderFavorite(customerId, providerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider removed from favorites')),
        );
        _loadFavorites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeItemFavorite(String itemId) async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites'),
        content: const Text('Remove this item from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final favoritesService = FavoritesService();

    try {
      await favoritesService.removeItemFavorite(customerId, itemId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from favorites')),
        );
        _loadFavorites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.favorite)),
            Tab(text: 'Providers', icon: Icon(Icons.business)),
            Tab(text: 'Items', icon: Icon(Icons.inventory_2)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllFavoritesTab(),
                _buildProviderFavoritesTab(),
                _buildItemFavoritesTab(),
              ],
            ),
    );
  }

  Widget _buildAllFavoritesTab() {
    if (_allFavorites.isEmpty) {
      return _buildEmptyState('No favorites yet', 'Start adding your favorites!');
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allFavorites.length,
        itemBuilder: (context, index) {
          final favoriteGroup = _allFavorites[index];
          final provider = favoriteGroup['provider'] as Map<String, dynamic>;
          final items = favoriteGroup['items'] as List<dynamic>;
          final isProviderFavorited = favoriteGroup['is_provider_favorited'] as bool;

          return _buildProviderGroupCard(provider, items, isProviderFavorited);
        },
      ),
    );
  }

  Widget _buildProviderFavoritesTab() {
    if (_providerFavorites.isEmpty) {
      return _buildEmptyState(
        'No provider favorites',
        'Favorite providers to see them here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _providerFavorites.length,
        itemBuilder: (context, index) {
          final favorite = _providerFavorites[index];
          final provider = favorite['providers'] as Map<String, dynamic>;
          return _buildProviderCard(provider);
        },
      ),
    );
  }

  Widget _buildItemFavoritesTab() {
    if (_itemFavorites.isEmpty) {
      return _buildEmptyState(
        'No item favorites',
        'Favorite items to see them here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _itemFavorites.length,
        itemBuilder: (context, index) {
          final favorite = _itemFavorites[index];
          final item = favorite['items'] as Map<String, dynamic>;
          return _buildItemCard(item);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderGroupCard(
    Map<String, dynamic> provider,
    List<dynamic> items,
    bool isProviderFavorited,
  ) {
    final companyName = provider['company_name_en'] as String;
    final location = provider['store_location'] as String;
    final photoUrl = provider['profile_photo_url'] as String?;
    final providerId = provider['id'] as String;
    final averageRating = (provider['average_rating'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Header
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProviderDetailScreen(
                    providerId: providerId,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? const Icon(Icons.business) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                companyName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isProviderFavorited)
                              Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isProviderFavorited)
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => _removeProviderFavorite(providerId),
                    ),
                ],
              ),
            ),
          ),

          // Favorited Items from this Provider
          if (items.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favorited Items (${items.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((itemData) {
                    final item = itemData['item'] as Map<String, dynamic>;
                    return _buildCompactItemCard(item);
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final companyName = provider['company_name_en'] as String;
    final location = provider['store_location'] as String;
    final photoUrl = provider['profile_photo_url'] as String?;
    final description = provider['store_description'] as String?;
    final providerId = provider['id'] as String;
    final averageRating = (provider['average_rating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = provider['total_reviews'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderDetailScreen(
                providerId: providerId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? const Icon(Icons.business, size: 30) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${averageRating.toStringAsFixed(1)} ($totalReviews)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () => _removeProviderFavorite(providerId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final name = item['name'] as String;
    final price = (item['price'] as num).toDouble();
    final pricingType = item['pricing_type'] as String;
    final photoUrls = item['photo_urls'] as List<dynamic>?;
    final itemId = item['id'] as String;
    final stockQuantity = item['stock_quantity'] as int;
    final provider = item['providers'] as Map<String, dynamic>;
    final companyName = provider['company_name_en'] as String;

    final photoUrl = (photoUrls != null && photoUrls.isNotEmpty)
        ? photoUrls.first as String
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(itemId: itemId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      companyName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$price SAR',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pricingType == 'per_day'
                          ? 'Per Day'
                          : pricingType == 'per_event'
                              ? 'Per Event'
                              : 'Purchase',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (stockQuantity == 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () => _removeItemFavorite(itemId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactItemCard(Map<String, dynamic> item) {
    final name = item['name'] as String;
    final price = (item['price'] as num).toDouble();
    final photoUrls = item['photo_urls'] as List<dynamic>?;
    final itemId = item['id'] as String;

    final photoUrl = (photoUrls != null && photoUrls.isNotEmpty)
        ? photoUrls.first as String
        : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(itemId: itemId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 20),
                        );
                      },
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 20),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$price SAR',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
              onPressed: () => _removeItemFavorite(itemId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
