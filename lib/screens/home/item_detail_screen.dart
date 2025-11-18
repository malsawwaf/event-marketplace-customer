import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/items_service.dart';
import '../../services/stock_service.dart';
import '../../services/cart_service.dart';
import '../../services/favourites_service.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
  // Map of group ID to set of selected option IDs
  final Map<String, Set<String>> _selectedAddonOptions = {};
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
    final l10n = AppLocalizations.of(context);
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addToFavorites)),
      );
      return;
    }

    final favoritesService = FavoritesService();
    try {
      final newStatus = await favoritesService.toggleItemFavorite(customerId, widget.itemId);
      
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _isFavorited = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? l10n.addToFavorites : l10n.removeFromFavorites),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSavingData)),
        );
      }
    }
  }

  Future<void> _addToCart() async {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addToCart)),
      );
      return;
    }

    // Validate required add-on groups
    final addonGroups = _itemData!['item_addon_groups'] as List<dynamic>?;
    if (addonGroups != null) {
      for (final group in addonGroups) {
        final groupMap = Map<String, dynamic>.from(group);
        final groupId = groupMap['id'] as String;
        final groupName = isArabic && groupMap['name_ar'] != null ? groupMap['name_ar'] as String : groupMap['name'] as String;
        final isRequired = groupMap['is_required'] as bool? ?? false;
        final selectionType = groupMap['selection_type'] as String? ?? 'single';
        final minSelection = groupMap['min_selection'] as int? ?? 1;
        final maxSelection = groupMap['max_selection'] as int?;

        final selectedOptions = _selectedAddonOptions[groupId] ?? {};
        final selectedCount = selectedOptions.length;

        // Check if required group has no selections
        if (isRequired && selectedCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.selectOptions} "$groupName"')),
          );
          return;
        }

        // For multiple selection, check min/max constraints
        if (selectionType == 'multiple' && selectedCount > 0) {
          if (selectedCount < minSelection) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.select} $minSelection ${l10n.optional} "$groupName"')),
            );
            return;
          }
          if (maxSelection != null && selectedCount > maxSelection) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.select} $maxSelection ${l10n.optional} "$groupName"')),
            );
            return;
          }
        }
      }
    }

    // Collect all selected addon option IDs from all groups
    final allSelectedAddons = <String>{};
    for (final optionIds in _selectedAddonOptions.values) {
      allSelectedAddons.addAll(optionIds);
    }

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
        final l10n = AppLocalizations.of(context);
        setState(() => _isAddingToCart = false);

        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addToCart),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.itemDetails)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_itemData == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.itemDetails)),
        body: Center(child: Text(l10n.noItems)),
      );
    }

    final nameEn = _itemData!['name'] as String;
    final nameAr = _itemData!['name_ar'] as String?;
    final name = isArabic && nameAr != null ? nameAr : nameEn;

    final descriptionEn = _itemData!['description'] as String? ?? '';
    final descriptionAr = _itemData!['description_ar'] as String?;
    final description = isArabic && descriptionAr != null ? descriptionAr : descriptionEn;

    final price = (_itemData!['price'] as num).toDouble();
    final pricingType = _itemData!['pricing_type'] as String;
    final stockQuantity = _itemData!['stock_quantity'] as int;
    final minQuantity = _itemData!['min_order_quantity'] as int? ?? 1;
    final maxQuantity = _itemData!['max_order_quantity'] as int?;
    final photoUrls = _itemData!['photo_urls'] as List<dynamic>?;
    final provider = _itemData!['providers'] as Map<String, dynamic>;
    final addonGroups = _itemData!['item_addon_groups'] as List<dynamic>?;

    final itemsService = ItemsService();

    return Scaffold(
      appBar: AppBar(
        title: Text(name, textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr),
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
                                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '$price ${l10n.sar}',
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
                          Text(
                            l10n.itemDetails,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Add-ons Section
                        if (addonGroups != null && addonGroups.isNotEmpty) ...[
                          _buildAddonGroupsSection(addonGroups),
                          const SizedBox(height: 16),
                        ],

                        // Quantity Selector
                        _buildQuantitySelector(minQuantity, maxQuantity),
                        const SizedBox(height: 16),

                        // Notes
                        TextField(
                          decoration: InputDecoration(
                            labelText: l10n.specialInstructions,
                            border: const OutlineInputBorder(),
                            hintText: l10n.specialInstructions,
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
                        ? AppTheme.primaryNavy
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
    final l10n = AppLocalizations.of(context);
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (stockQuantity == 0) {
      statusColor = Colors.red;
      statusText = l10n.outOfStock;
      statusIcon = Icons.cancel;
    } else if (stockQuantity < 5) {
      statusColor = Colors.orange;
      statusText = '${l10n.inStock} ($_availableStock ${l10n.items})';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = '${l10n.inStock} ($_availableStock ${l10n.items})';
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final companyNameEn = provider['company_name_en'] as String;
    final companyNameAr = provider['company_name_ar'] as String?;
    final companyName = isArabic && companyNameAr != null ? companyNameAr : companyNameEn;

    final city = provider['city'] as String? ?? '';
    final country = provider['country'] as String? ?? '';
    final photoUrl = provider['profile_photo_url'] as String?;

    final location = city.isNotEmpty
        ? (country.isNotEmpty ? '$city, $country' : city)
        : (country.isNotEmpty ? country : '');

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
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (location.isNotEmpty) ...[
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonGroupsSection(List<dynamic> groups) {
    final l10n = AppLocalizations.of(context);
    // Separate required and optional groups
    final List<Map<String, dynamic>> requiredGroups = [];
    final List<Map<String, dynamic>> optionalGroups = [];

    for (final group in groups) {
      final groupMap = Map<String, dynamic>.from(group);
      final isRequired = groupMap['is_required'] as bool? ?? false;

      if (isRequired) {
        requiredGroups.add(groupMap);
      } else {
        optionalGroups.add(groupMap);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Required Add-on Groups
        if (requiredGroups.isNotEmpty) ...[
          Text(
            l10n.required,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          ...requiredGroups.map((group) => _buildAddonGroup(group)),
          const SizedBox(height: 16),
        ],

        // Optional Add-on Groups
        if (optionalGroups.isNotEmpty) ...[
          Text(
            l10n.optional,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...optionalGroups.map((group) => _buildAddonGroup(group)),
        ],
      ],
    );
  }

  Widget _buildAddonGroup(Map<String, dynamic> group) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final groupId = group['id'] as String;
    final groupNameEn = group['name'] as String;
    final groupNameAr = group['name_ar'] as String?;
    final groupName = isArabic && groupNameAr != null ? groupNameAr : groupNameEn;

    final groupDescriptionEn = group['description'] as String?;
    final groupDescriptionAr = group['description_ar'] as String?;
    final groupDescription = isArabic && groupDescriptionAr != null ? groupDescriptionAr : groupDescriptionEn;

    final selectionType = group['selection_type'] as String? ?? 'single';
    final minSelection = group['min_selection'] as int? ?? 1;
    final maxSelection = group['max_selection'] as int?;
    final options = group['item_addon_options'] as List<dynamic>?;

    if (options == null || options.isEmpty) {
      return const SizedBox.shrink();
    }

    String selectionInfo = '';
    if (selectionType == 'multiple') {
      if (maxSelection != null) {
        selectionInfo = ' (${l10n.select} $minSelection-$maxSelection)';
      } else {
        selectionInfo = minSelection > 1 ? ' (${l10n.select} $minSelection)' : ' (${l10n.select})';
      }
    } else {
      selectionInfo = ' (${l10n.select})';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    groupName + selectionInfo,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (groupDescription != null && groupDescription.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                groupDescription,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Display options based on selection type
            if (selectionType == 'single')
              ...options.map((option) => _buildRadioOption(groupId, option))
            else
              ...options.map((option) => _buildCheckboxOption(groupId, option, maxSelection)),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String groupId, dynamic option) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final optionMap = Map<String, dynamic>.from(option);
    final optionId = optionMap['id'] as String;
    final optionNameEn = optionMap['name'] as String;
    final optionNameAr = optionMap['name_ar'] as String?;
    final optionName = isArabic && optionNameAr != null ? optionNameAr : optionNameEn;

    final optionDescriptionEn = optionMap['description'] as String?;
    final optionDescriptionAr = optionMap['description_ar'] as String?;
    final optionDescription = isArabic && optionDescriptionAr != null ? optionDescriptionAr : optionDescriptionEn;

    final price = (optionMap['additional_price'] as num?)?.toDouble() ?? 0.0;

    final selectedOptions = _selectedAddonOptions[groupId] ?? {};
    final isSelected = selectedOptions.contains(optionId);

    return RadioListTile<String>(
      title: Text(
        optionName,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (optionDescription != null && optionDescription.isNotEmpty)
            Text(
              optionDescription,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (price > 0) Text('+$price ${l10n.sar}', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
      value: optionId,
      groupValue: isSelected ? optionId : (selectedOptions.isNotEmpty ? selectedOptions.first : null),
      onChanged: (value) {
        setState(() {
          if (value != null) {
            // If tapping the already selected option, deselect it
            if (selectedOptions.contains(value)) {
              _selectedAddonOptions[groupId] = {};
            } else {
              _selectedAddonOptions[groupId] = {value};
            }
          } else {
            _selectedAddonOptions[groupId] = {};
          }
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCheckboxOption(String groupId, dynamic option, int? maxSelection) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final optionMap = Map<String, dynamic>.from(option);
    final optionId = optionMap['id'] as String;
    final optionNameEn = optionMap['name'] as String;
    final optionNameAr = optionMap['name_ar'] as String?;
    final optionName = isArabic && optionNameAr != null ? optionNameAr : optionNameEn;

    final optionDescriptionEn = optionMap['description'] as String?;
    final optionDescriptionAr = optionMap['description_ar'] as String?;
    final optionDescription = isArabic && optionDescriptionAr != null ? optionDescriptionAr : optionDescriptionEn;

    final price = (optionMap['additional_price'] as num?)?.toDouble() ?? 0.0;

    final selectedOptions = _selectedAddonOptions[groupId] ?? {};
    final isSelected = selectedOptions.contains(optionId);
    final isMaxReached = maxSelection != null && selectedOptions.length >= maxSelection;

    return CheckboxListTile(
      title: Text(
        optionName,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (optionDescription != null && optionDescription.isNotEmpty)
            Text(
              optionDescription,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (price > 0) Text('+$price ${l10n.sar}', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
      value: isSelected,
      onChanged: (isMaxReached && !isSelected) ? null : (value) {
        setState(() {
          if (!_selectedAddonOptions.containsKey(groupId)) {
            _selectedAddonOptions[groupId] = {};
          }
          if (value == true) {
            _selectedAddonOptions[groupId]!.add(optionId);
          } else {
            _selectedAddonOptions[groupId]!.remove(optionId);
          }
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuantitySelector(int minQuantity, int? maxQuantity) {
    final l10n = AppLocalizations.of(context);
    final effectiveMax = maxQuantity ?? _availableStock;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.quantity,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    final l10n = AppLocalizations.of(context);
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
              backgroundColor: AppTheme.primaryNavy,
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
                    canAddToCart ? l10n.addToCart : l10n.outOfStock,
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
