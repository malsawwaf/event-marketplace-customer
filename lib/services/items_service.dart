import 'package:supabase_flutter/supabase_flutter.dart';

class ItemsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch items for a specific provider, grouped by category
  /// Includes add-ons with selection_type for each item
  Future<Map<String, List<Map<String, dynamic>>>> fetchItemsByProvider(
    String providerId,
  ) async {
    try {
      // Fetch items with their add-ons
      final response = await _supabase
          .from('items')
          .select('*, item_addons(*)')
          .eq('provider_id', providerId)
          .eq('is_enabled', true)
          .order('category')
          .order('created_at', ascending: false);

      if (response is List) {
        final items = response.map((item) => Map<String, dynamic>.from(item)).toList();

        // Group items by category
        final Map<String, List<Map<String, dynamic>>> groupedItems = {};

        for (final item in items) {
          final category = item['category'] as String;

          if (!groupedItems.containsKey(category)) {
            groupedItems[category] = [];
          }

          groupedItems[category]!.add(item);
        }

        return groupedItems;
      }

      return {};
    } catch (e) {
      print('Error fetching items: $e');
      return {};
    }
  }

  /// Fetch a single item with full details including add-ons
  Future<Map<String, dynamic>?> fetchItemById(String itemId) async {
    try {
      final response = await _supabase
          .from('items')
          .select('*, item_addons(*), providers!inner(company_name_en, company_name_ar, profile_photo_url, store_location, price_range)')
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
  Future<List<Map<String, dynamic>>> fetchAllItems({
    String? category,
    String? searchQuery,
    String? sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase
          .from('items')
          .select('*, item_addons(*), providers!inner(company_name_en, profile_photo_url, store_location, average_rating)')
          .eq('is_enabled', true)
          .eq('providers.is_active', true);

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
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

  /// Get add-ons for a specific item
  /// Returns list with selection_type included
  Future<List<Map<String, dynamic>>> fetchItemAddons(String itemId) async {
    try {
      final response = await _supabase
          .from('item_addons')
          .select()
          .eq('item_id', itemId)
          .order('name');

      if (response is List) {
        return response.map((addon) => Map<String, dynamic>.from(addon)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching item add-ons: $e');
      return [];
    }
  }

  /// Get required add-ons for an item
  Future<List<Map<String, dynamic>>> fetchRequiredAddons(String itemId) async {
    try {
      final response = await _supabase
          .from('item_addons')
          .select()
          .eq('item_id', itemId)
          .eq('is_required', true)
          .order('name');

      if (response is List) {
        return response.map((addon) => Map<String, dynamic>.from(addon)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching required add-ons: $e');
      return [];
    }
  }

  /// Get optional add-ons for an item
  Future<List<Map<String, dynamic>>> fetchOptionalAddons(String itemId) async {
    try {
      final response = await _supabase
          .from('item_addons')
          .select()
          .eq('item_id', itemId)
          .eq('is_required', false)
          .order('name');

      if (response is List) {
        return response.map((addon) => Map<String, dynamic>.from(addon)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching optional add-ons: $e');
      return [];
    }
  }

  /// Check if item has any required add-ons
  Future<bool> hasRequiredAddons(String itemId) async {
    try {
      final response = await _supabase
          .from('item_addons')
          .select('id')
          .eq('item_id', itemId)
          .eq('is_required', true)
          .limit(1);

      if (response is List) {
        return response.isNotEmpty;
      }

      return false;
    } catch (e) {
      print('Error checking required add-ons: $e');
      return false;
    }
  }

  /// Get pricing type label for display
  String getPricingTypeLabel(String pricingType) {
    switch (pricingType) {
      case 'per_day':
        return 'Per Day';
      case 'per_event':
        return 'Per Event';
      case 'purchasable':
        return 'One-time Purchase';
      default:
        return 'Per Event';
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

  /// Get first photo URL from item's photo_urls array
  String? getFirstPhotoUrl(Map<String, dynamic> item) {
    final photoUrls = item['photo_urls'] as List<dynamic>?;
    if (photoUrls != null && photoUrls.isNotEmpty) {
      return photoUrls.first as String?;
    }
    return null;
  }

  /// Format price with pricing type
  String formatPrice(Map<String, dynamic> item) {
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final pricingType = item['pricing_type'] as String? ?? 'per_event';
    final label = getPricingTypeLabel(pricingType);
    return '$price SAR $label';
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