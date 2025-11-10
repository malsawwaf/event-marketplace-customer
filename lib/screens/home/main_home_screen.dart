import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/categories.dart';
import '../../services/provider_service.dart';
import '../../services/favourites_service.dart';
import '../../widgets/provider_card_widget.dart';
import 'provider_detail_screen.dart';

class MainHomeScreen extends StatefulWidget {
  final VoidCallback? onCartUpdate;
  const MainHomeScreen({
    Key? key,
    this.onCartUpdate,
  }) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final _supabase = Supabase.instance.client;
  final ProviderService _providerService = ProviderService();
  final FavoritesService _favoritesService = FavoritesService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _featuredProviders = [];
  List<Map<String, dynamic>> _allProviders = [];
  Set<String> _favoriteIds = {};
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customerId = _supabase.auth.currentUser?.id;
      
      final featured = await _providerService.getFeaturedProviders(limit: 5);
      final all = await _providerService.getProviders();
      
      final favIds = customerId != null
          ? await _favoritesService.getProviderFavoriteIds(customerId)
          : <String>{};

      setState(() {
        _featuredProviders = featured;
        _allProviders = all;
        _favoriteIds = favIds;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedCategory == null) {
      _loadData();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _providerService.searchProviders(
        query: query.isEmpty ? null : query,
        category: _selectedCategory,
      );

      setState(() {
        _allProviders = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategory = categoryId == _selectedCategory ? null : categoryId;
    });
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Marketplace'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.blue[700],
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search providers, services...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadData();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => _search(),
                      ),
                    ),
                  ),
                  // Category Chips
                  SliverToBoxAdapter(
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: EventCategories.all.length,
                        itemBuilder: (context, index) {
                          final category = EventCategories.all[index];
                          final isSelected = _selectedCategory == category.id;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    category.icon,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : category.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(category.name),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (_) => _selectCategory(category.id),
                              backgroundColor: Colors.white,
                              selectedColor: category.color,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? category.color
                                    : Colors.grey[300]!,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Featured Providers Section
                  if (_featuredProviders.isNotEmpty &&
                      _selectedCategory == null &&
                      _searchController.text.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber[700]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Featured Providers',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _featuredProviders.length,
                                itemBuilder: (context, index) {
                                  final provider = _featuredProviders[index];
                                  return SizedBox(
                                    width: 250,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: GestureDetector(
                                        onTap: () async {
                                          final result = await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => ProviderDetailScreen(
                                                providerId: provider['id'] as String,
                                              ),
                                            ),
                                          );
                                          // Refresh cart count if item was added
                                          if (result == true && widget.onCartUpdate != null) {
                                            widget.onCartUpdate!();
                                          }
                                        },
                                        child: ProviderCardWidget(
                                          provider: provider,
                                          onTap: () async {
                                            final result = await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => ProviderDetailScreen(
                                                  providerId: provider['id'] as String,
                                                ),
                                              ),
                                            );
                                            if (result == true && widget.onCartUpdate != null) {
                                              widget.onCartUpdate!();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // All Providers Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        _selectedCategory != null ||
                                _searchController.text.isNotEmpty
                            ? 'Search Results (${_allProviders.length})'
                            : 'All Providers',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // All Providers Grid
                  _allProviders.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No providers found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final provider = _allProviders[index];
                                return ProviderCardWidget(
                                  provider: provider,
                                  onTap: () async {
                                    final result = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ProviderDetailScreen(
                                          providerId: provider['id'] as String,
                                        ),
                                      ),
                                    );
                                    if (result == true && widget.onCartUpdate != null) {
                                      widget.onCartUpdate!();
                                    }
                                  },
                                );
                              },
                              childCount: _allProviders.length,
                            ),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}