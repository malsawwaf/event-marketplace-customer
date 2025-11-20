import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';

class ItemsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch items for a specific provider, grouped by category
  /// Includes add-on groups with their options for each item
  Future<Map<String, List<Map<String, dynamic>>>> fetchItemsByProvider(
    String providerId,
  ) async {
    try {
      // Fetch items with their add-on groups and options, plus category name
      final response = await _supabase
          .from('items')
          .select('''
            *,
            item_categories!inner(id, name, name_ar),
            item_addon_groups(
              id,
              name,
              name_ar,
              description,
              description_ar,
              is_required,
              selection_type,
              min_selection,
              max_selection,
              display_order,
              item_addon_options(
                id,
                name,
                name_ar,
                description,
                description_ar,
                photo_url,
                additional_price,
                display_order
              )
            )
          ''')
          .eq('provider_id', providerId)
          .eq('is_enabled', true)
          .order('category_id')
          .order('created_at', ascending: false);

      if (response is List) {
        final items = response.map((item) => Map<String, dynamic>.from(item)).toList();

        // Group items by category name
        final Map<String, List<Map<String, dynamic>>> groupedItems = {};

        for (final item in items) {
          final categoryData = item['item_categories'] as Map<String, dynamic>?;
          final categoryName = categoryData?['name'] as String? ?? 'Uncategorized';

          if (!groupedItems.containsKey(categoryName)) {
            groupedItems[categoryName] = [];
          }

          groupedItems[categoryName]!.add(item);
        }

        return groupedItems;
      }

      return {};
    } catch (e) {
      print('Error fetching items: $e');
      return {};
    }
  }

  /// Fetch a single item with full details including add-on groups and options
  Future<Map<String, dynamic>?> fetchItemById(String itemId) async {
    try {
      final response = await _supabase
          .from('items')
          .select('''
            *,
            item_categories(id, name, name_ar),
            item_addon_groups(
              id,
              name,
              name_ar,
              description,
              description_ar,
              is_required,
              selection_type,
              min_selection,
              max_selection,
              display_order,
              item_addon_options(
                id,
                name,
                name_ar,
                description,
                description_ar,
                photo_url,
                additional_price,
                display_order
              )
            ),
            providers!inner(company_name_en, company_name_ar, trading_name, profile_photo_url, store_location, store_location_ar, price_range, city, country)
          ''')
          .eq('id', itemId)
          .eq('is_enabled', true)
          .single();

      return response;
    } catch (e) {
      print('Error fetching item by ID: $e');
      return null;
    }
  }

  /// Fetch all items across all providers (for search/browse)
  /// category parameter filters by item category name (e.g., "Wooden Chairs")
  Future<List<Map<String, dynamic>>> fetchAllItems({
    String? category,
    String? searchQuery,
    String? sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase
          .from('items')
          .select('''
            *,
            item_categories(id, name, name_ar),
            item_addon_groups(
              id,
              name,
              name_ar,
              description,
              description_ar,
              is_required,
              selection_type,
              min_selection,
              max_selection,
              display_order,
              item_addon_options(
                id,
                name,
                name_ar,
                description,
                description_ar,
                photo_url,
                additional_price,
                display_order
              )
            ),
            providers!inner(company_name_en, company_name_ar, trading_name, profile_photo_url, store_location, average_rating)
          ''')
          .eq('is_enabled', true)
          .eq('providers.is_active', true);

      // Apply category filter (by category name through join)
      if (category != null && category.isNotEmpty) {
        query = query.eq('item_categories.name', category);
      }

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      // Apply sorting
      final response = await query.order(sortBy ?? 'created_at', ascending: ascending);

      if (response is List) {
        return response.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching all items: $e');
      return [];
    }
  }

  /// Get add-on groups with their options for a specific item
  /// Returns list of groups with nested options
  Future<List<Map<String, dynamic>>> fetchItemAddonGroups(String itemId) async {
    try {
      final response = await _supabase
          .from('item_addon_groups')
          .select('''
            id,
            name,
            description,
            is_required,
            selection_type,
            min_selection,
            max_selection,
            display_order,
            item_addon_options(
              id,
              name,
              description,
              photo_url,
              additional_price,
              display_order
            )
          ''')
          .eq('item_id', itemId)
          .order('display_order');

      if (response is List) {
        return response.map((group) => Map<String, dynamic>.from(group)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching item add-on groups: $e');
      return [];
    }
  }

  /// Get required add-on groups for an item
  Future<List<Map<String, dynamic>>> fetchRequiredAddonGroups(String itemId) async {
    try {
      final response = await _supabase
          .from('item_addon_groups')
          .select('''
            id,
            name,
            description,
            is_required,
            selection_type,
            min_selection,
            max_selection,
            display_order,
            item_addon_options(
              id,
              name,
              description,
              photo_url,
              additional_price,
              display_order
            )
          ''')
          .eq('item_id', itemId)
          .eq('is_required', true)
          .order('display_order');

      if (response is List) {
        return response.map((group) => Map<String, dynamic>.from(group)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching required add-on groups: $e');
      return [];
    }
  }

  /// Get optional add-on groups for an item
  Future<List<Map<String, dynamic>>> fetchOptionalAddonGroups(String itemId) async {
    try {
      final response = await _supabase
          .from('item_addon_groups')
          .select('''
            id,
            name,
            description,
            is_required,
            selection_type,
            min_selection,
            max_selection,
            display_order,
            item_addon_options(
              id,
              name,
              description,
              photo_url,
              additional_price,
              display_order
            )
          ''')
          .eq('item_id', itemId)
          .eq('is_required', false)
          .order('display_order');

      if (response is List) {
        return response.map((group) => Map<String, dynamic>.from(group)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching optional add-on groups: $e');
      return [];
    }
  }

  /// Check if item has any required add-on groups
  Future<bool> hasRequiredAddonGroups(String itemId) async {
    try {
      final response = await _supabase
          .from('item_addon_groups')
          .select('id')
          .eq('item_id', itemId)
          .eq('is_required', true)
          .limit(1);

      if (response is List) {
        return response.isNotEmpty;
      }

      return false;
    } catch (e) {
      print('Error checking required add-on groups: $e');
      return false;
    }
  }

  /// Get pricing type label for display
  String getPricingTypeLabel(String pricingType, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (pricingType) {
      case 'per_day':
        return l10n.perDay;
      case 'per_event':
        return l10n.perEvent;
      case 'purchasable':
        return l10n.purchase;
      default:
        return l10n.perEvent;
    }
  }

  /// Check if item supports date ranges (for rental items)
  bool supportsDateRange(String pricingType) {
    return pricingType == 'per_day';
  }

  /// Calculate item price based on pricing type and days
  double calculateItemPrice({
    required double basePrice,
    required String pricingType,
    required int quantity,
    int days = 1,
  }) {
    if (pricingType == 'per_day') {
      return basePrice * days * quantity;
    } else {
      // per_event or purchasable - days don't matter
      return basePrice * quantity;
    }
  }

  /// Get stock status label
  String getStockStatusLabel(int stockQuantity) {
    if (stockQuantity == 0) {
      return 'Out of Stock';
    } else if (stockQuantity < 5) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  /// Check if item is in stock
  bool isInStock(int stockQuantity) {
    return stockQuantity > 0;
  }

  /// Get featured items (for homepage)
  Future<List<Map<String, dynamic>>> fetchFeaturedItems({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('items')
          .select('*, providers!inner(company_name_en, profile_photo_url, is_featured)')
          .eq('is_enabled', true)
          .eq('providers.is_active', true)
          .eq('providers.is_featured', true)
          .order('created_at', ascending: false)
          .limit(limit);

      if (response is List) {
        return response.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching featured items: $e');
      return [];
    }
  }

  /// Get photo URL from item's photo_url field
  String? getFirstPhotoUrl(Map<String, dynamic> item) {
    return item['photo_url'] as String?;
  }

  /// Format price with pricing type
  String formatPrice(Map<String, dynamic> item, BuildContext context) {
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final pricingType = item['pricing_type'] as String? ?? 'per_event';
    final label = getPricingTypeLabel(pricingType, context);
    return '$price $label';
  }

  /// Check if item is in stock
  bool isItemInStock(Map<String, dynamic> item) {
    final stockQuantity = item['stock_quantity'] as int? ?? 0;
    return stockQuantity > 0;
  }

  /// Check if item has low stock
  bool isLowStock(Map<String, dynamic> item) {
    final stockQuantity = item['stock_quantity'] as int? ?? 0;
    return stockQuantity > 0 && stockQuantity < 5;
  }

  /// Get stock quantity
  int getStockQuantity(Map<String, dynamic> item) {
    return item['stock_quantity'] as int? ?? 0;
  }
}