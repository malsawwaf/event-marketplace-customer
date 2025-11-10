import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/items_service.dart';
import '../../services/stock_service.dart';
import '../../services/cart_service.dart';
import '../../services/favourites_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({
    Key? key,
    required this.itemId,
  }) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _itemData;
  bool _isLoading = true;
  bool _isAddingToCart = false;
  bool _isFavorited = false;
  int _availableStock = 0;
  
  int _quantity = 1;
  final Set<String> _selectedAddonIds = {};
  final Map<String, List<String>> _radioSelections = {}; // For single selection add-ons
  String? _notes;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
    _checkFavoriteStatus();
  }

  Future<void> _loadItemDetails() async {
    setState(() => _isLoading = true);

    final itemsService = ItemsService();
    final stockService = StockService();

    try {
      final itemData = await itemsService.fetchItemById(widget.itemId);
      final availableStock = await stockService.getAvailableStock(widget.itemId);

      if (mounted && itemData != null) {
        setState(() {
          _itemData = itemData;
          _availableStock = availableStock;
          _quantity = (itemData['min_order_quantity'] as int?) ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading item: $e')),
        );
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    final favoritesService = FavoritesService();
    final isFavorited = await favoritesService.isItemFavorited(customerId, widget.itemId);

    if (mounted) {
      setState(() => _isFavorited = isFavorited);
    }
  }

  Future<void> _toggleFavorite() async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    final favoritesService = FavoritesService();
    try {
      final newStatus = await favoritesService.toggleItemFavorite(customerId, widget.itemId);
      
      if (mounted) {
        setState(() => _isFavorited = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Added to favorites' : 'Removed from favorites'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite')),
        );
      }
    }
  }

  Future<void> _addToCart() async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add to cart')),
      );
      return;
    }

    // Validate required add-ons
    final addons = _itemData!['item_addons'] as List<dynamic>?;
    if (addons != null) {
      for (final addon in addons) {
        final isRequired = addon['is_required'] as bool? ?? false;
        final selectionType = addon['selection_type'] as String? ?? 'multiple';
        final addonId = addon['id'] as String;

        if (isRequired) {
          if (selectionType == 'single') {
            // Check if a selection was made in this radio group
            if (!_radioSelections.containsKey(addon['name']) || 
                _radioSelections[addon['name']]!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please select ${addon['name']}')),
              );
              return;
            }
          } else {
            // Multiple selection - check if this specific addon is selected
            if (!_selectedAddonIds.contains(addonId)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please select ${addon['name']}')),
              );
              return;
            }
          }
        }
      }
    }

    // Collect all selected addon IDs (both radio and checkbox)
    final allSelectedAddons = <String>{..._selectedAddonIds};
    _radioSelections.values.forEach((list) => allSelectedAddons.addAll(list));

    setState(() => _isAddingToCart = true);

    final stockService = StockService();
    final cartService = CartService();

    try {
      // Check stock availability
      await stockService.validateStockForCart(
        itemId: widget.itemId,
        requestedQuantity: _quantity,
      );

      // Add to cart
      await cartService.addItemToCart(
        customerId: customerId,
        providerId: _itemData!['provider_id'] as String,
        itemId: widget.itemId,
        quantity: _quantity,
        selectedAddonIds: allSelectedAddons.isEmpty ? null : allSelectedAddons.toList(),
        notes: _notes,
      );

      if (mounted) {
        setState(() => _isAddingToCart = false);
        
        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pop(context, true); // Return true to indicate cart was updated
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToCart = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_itemData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(child: Text('Item not found')),
      );
    }

    final name = _itemData!['name'] as String;
    final description = _itemData!['description'] as String? ?? '';
    final price = (_itemData!['price'] as num).toDouble();
    final pricingType = _itemData!['pricing_type'] as String;
    final stockQuantity = _itemData!['stock_quantity'] as int;
    final minQuantity = _itemData!['min_order_quantity'] as int? ?? 1;
    final maxQuantity = _itemData!['max_order_quantity'] as int?;
    final photoUrls = _itemData!['photo_urls'] as List<dynamic>?;
    final provider = _itemData!['providers'] as Map<String, dynamic>;
    final addons = _itemData!['item_addons'] as List<dynamic>?;

    final itemsService = ItemsService();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Gallery
                  _buildPhotoGallery(photoUrls),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Name and Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '$price SAR',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemsService.getPricingTypeLabel(pricingType),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stock Status
                        _buildStockStatus(stockQuantity),
                        const SizedBox(height: 16),

                        // Provider Info
                        _buildProviderInfo(provider),
                        const SizedBox(height: 16),

                        // Description
                        if (description.isNotEmpty) ...[
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(description),
                          const SizedBox(height: 16),
                        ],

                        // Add-ons Section
                        if (addons != null && addons.isNotEmpty) ...[
                          const Text(
                            'Add-ons',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildAddonsSection(addons),
                          const SizedBox(height: 16),
                        ],

                        // Quantity Selector
                        _buildQuantitySelector(minQuantity, maxQuantity),
                        const SizedBox(height: 16),

                        // Notes
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Special Notes (Optional)',
                            border: OutlineInputBorder(),
                            hintText: 'Add any special requests...',
                          ),
                          maxLines: 3,
                          onChanged: (value) => _notes = value.isEmpty ? null : value,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Add to Cart Button
          _buildAddToCartButton(),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(List<dynamic>? photoUrls) {
    if (photoUrls == null || photoUrls.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.image, size: 80)),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: photoUrls.length,
            onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
            itemBuilder: (context, index) {
              return Image.network(
                photoUrls[index] as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 80),
                  );
                },
              );
            },
          ),
        ),
        if (photoUrls.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photoUrls.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPhotoIndex == index
                        ? Colors.blue
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStockStatus(int stockQuantity) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (stockQuantity == 0) {
      statusColor = Colors.red;
      statusText = 'Out of Stock';
      statusIcon = Icons.cancel;
    } else if (stockQuantity < 5) {
      statusColor = Colors.orange;
      statusText = 'Low Stock ($_availableStock available)';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'In Stock ($_availableStock available)';
      statusIcon = Icons.check_circle;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProviderInfo(Map<String, dynamic> provider) {
    final companyName = provider['company_name_en'] as String;
    final location = provider['store_location'] as String;
    final photoUrl = provider['profile_photo_url'] as String?;

    return Card(
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonsSection(List<dynamic> addons) {
    // Group add-ons by selection type and name (for radio groups)
    final Map<String, List<Map<String, dynamic>>> radioGroups = {};
    final List<Map<String, dynamic>> checkboxAddons = [];

    for (final addon in addons) {
      final addonMap = Map<String, dynamic>.from(addon);
      final selectionType = addonMap['selection_type'] as String? ?? 'multiple';
      
      if (selectionType == 'single') {
        final name = addonMap['name'] as String;
        if (!radioGroups.containsKey(name)) {
          radioGroups[name] = [];
        }
        radioGroups[name]!.add(addonMap);
      } else {
        checkboxAddons.add(addonMap);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Radio groups (single selection)
        ...radioGroups.entries.map((entry) => _buildRadioGroup(entry.key, entry.value)),
        
        // Checkboxes (multiple selection)
        ...checkboxAddons.map(_buildCheckboxAddon),
      ],
    );
  }

  Widget _buildRadioGroup(String groupName, List<Map<String, dynamic>> options) {
    final isRequired = options.first['is_required'] as bool? ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...options.map((option) {
              final id = option['id'] as String;
              final name = option['name'] as String;
              final price = (option['additional_price'] as num).toDouble();
              final isSelected = _radioSelections[groupName]?.contains(id) ?? false;

              return RadioListTile<String>(
                title: Text(name),
                subtitle: price > 0 ? Text('+$price SAR') : null,
                value: id,
                groupValue: _radioSelections[groupName]?.firstOrNull,
                onChanged: (value) {
                  setState(() {
                    _radioSelections[groupName] = value != null ? [value] : [];
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxAddon(Map<String, dynamic> addon) {
    final id = addon['id'] as String;
    final name = addon['name'] as String;
    final price = (addon['additional_price'] as num).toDouble();
    final isRequired = addon['is_required'] as bool? ?? false;

    return CheckboxListTile(
      title: Row(
        children: [
          Expanded(child: Text(name)),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
      subtitle: price > 0 ? Text('+$price SAR') : null,
      value: _selectedAddonIds.contains(id),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _selectedAddonIds.add(id);
          } else {
            _selectedAddonIds.remove(id);
          }
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuantitySelector(int minQuantity, int? maxQuantity) {
    final effectiveMax = maxQuantity ?? _availableStock;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quantity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _quantity <= minQuantity
                      ? null
                      : () => setState(() => _quantity--),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _quantity >= effectiveMax
                      ? null
                      : () => setState(() => _quantity++),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    final canAddToCart = _availableStock > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: canAddToCart && !_isAddingToCart ? _addToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isAddingToCart
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    canAddToCart ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
