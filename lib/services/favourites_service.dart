import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== ITEM FAVORITES ====================

  /// Add item to favorites
  Future<void> addItemFavorite(String customerId, String itemId) async {
    try {
      await _supabase.from('item_favorites').insert({
        'customer_id': customerId,
        'item_id': itemId,
      });
    } catch (e) {
      print('Error adding item to favorites: $e');
      rethrow;
    }
  }

  /// Remove item from favorites
  Future<void> removeItemFavorite(String customerId, String itemId) async {
    try {
      await _supabase
          .from('item_favorites')
          .delete()
          .eq('customer_id', customerId)
          .eq('item_id', itemId);
    } catch (e) {
      print('Error removing item from favorites: $e');
      rethrow;
    }
  }

  /// Check if item is favorited
  Future<bool> isItemFavorited(String customerId, String itemId) async {
    try {
      final response = await _supabase
          .from('item_favorites')
          .select('id')
          .eq('customer_id', customerId)
          .eq('item_id', itemId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking item favorite status: $e');
      return false;
    }
  }

  /// Toggle item favorite status
  Future<bool> toggleItemFavorite(String customerId, String itemId) async {
    try {
      final isFavorited = await isItemFavorited(customerId, itemId);

      if (isFavorited) {
        await removeItemFavorite(customerId, itemId);
        return false;
      } else {
        await addItemFavorite(customerId, itemId);
        return true;
      }
    } catch (e) {
      print('Error toggling item favorite: $e');
      rethrow;
    }
  }

  /// Get all favorited items for a customer with full details
  Future<List<Map<String, dynamic>>> getItemFavorites(String customerId) async {
    try {
      final response = await _supabase
          .from('item_favorites')
          .select('''
            id,
            created_at,
            items!inner(
              id,
              name,
              price,
              pricing_type,
              photo_urls,
              stock_quantity,
              category,
              provider_id,
              providers!inner(
                id,
                company_name_en,
                company_name_ar,
                profile_photo_url,
                store_location,
                price_range,
                average_rating
              )
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      if (response is List) {
        return response.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching item favorites: $e');
      return [];
    }
  }

  /// Get favorited item IDs (for quick lookup)
  Future<Set<String>> getItemFavoriteIds(String customerId) async {
    try {
      final response = await _supabase
          .from('item_favorites')
          .select('item_id')
          .eq('customer_id', customerId);

      if (response is List) {
        return response.map((item) => item['item_id'] as String).toSet();
      }

      return {};
    } catch (e) {
      print('Error fetching item favorite IDs: $e');
      return {};
    }
  }

  // ==================== PROVIDER FAVORITES ====================

  /// Add provider to favorites
  Future<void> addProviderFavorite(String customerId, String providerId) async {
    try {
      await _supabase.from('provider_favorites').insert({
        'customer_id': customerId,
        'provider_id': providerId,
      });
    } catch (e) {
      print('Error adding provider to favorites: $e');
      rethrow;
    }
  }

  /// Remove provider from favorites
  Future<void> removeProviderFavorite(String customerId, String providerId) async {
    try {
      await _supabase
          .from('provider_favorites')
          .delete()
          .eq('customer_id', customerId)
          .eq('provider_id', providerId);
    } catch (e) {
      print('Error removing provider from favorites: $e');
      rethrow;
    }
  }

  /// Check if provider is favorited
  Future<bool> isProviderFavorited(String customerId, String providerId) async {
    try {
      final response = await _supabase
          .from('provider_favorites')
          .select('id')
          .eq('customer_id', customerId)
          .eq('provider_id', providerId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking provider favorite status: $e');
      return false;
    }
  }

  /// Toggle provider favorite status
  Future<bool> toggleProviderFavorite(String customerId, String providerId) async {
    try {
      final isFavorited = await isProviderFavorited(customerId, providerId);

      if (isFavorited) {
        await removeProviderFavorite(customerId, providerId);
        return false;
      } else {
        await addProviderFavorite(customerId, providerId);
        return true;
      }
    } catch (e) {
      print('Error toggling provider favorite: $e');
      rethrow;
    }
  }

  /// Get all favorited providers for a customer with full details
  Future<List<Map<String, dynamic>>> getProviderFavorites(String customerId) async {
    try {
      final response = await _supabase
          .from('provider_favorites')
          .select('''
            id,
            created_at,
            providers!inner(
              id,
              company_name_en,
              company_name_ar,
              profile_photo_url,
              store_location,
              store_description,
              price_range,
              average_rating,
              total_reviews,
              category,
              is_featured
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      if (response is List) {
        return response.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching provider favorites: $e');
      return [];
    }
  }

  /// Get favorited provider IDs (for quick lookup)
  Future<Set<String>> getProviderFavoriteIds(String customerId) async {
    try {
      final response = await _supabase
          .from('provider_favorites')
          .select('provider_id')
          .eq('customer_id', customerId);

      if (response is List) {
        return response.map((item) => item['provider_id'] as String).toSet();
      }

      return {};
    } catch (e) {
      print('Error fetching provider favorite IDs: $e');
      return {};
    }
  }

  // ==================== COMBINED FAVORITES ====================

  /// Get all favorites (both items and providers) grouped by provider
  /// Returns a list where each entry contains a provider and their favorited items
  Future<List<Map<String, dynamic>>> getAllFavorites(String customerId) async {
    try {
      // Get favorited providers
      final providerFavorites = await getProviderFavorites(customerId);
      
      // Get favorited items
      final itemFavorites = await getItemFavorites(customerId);

      // Group items by provider
      final Map<String, Map<String, dynamic>> providerMap = {};

      // Add favorited providers to map
      for (final providerFav in providerFavorites) {
        final provider = providerFav['providers'] as Map<String, dynamic>;
        final providerId = provider['id'] as String;

        providerMap[providerId] = {
          'provider': provider,
          'is_provider_favorited': true,
          'items': [],
          'provider_favorite_id': providerFav['id'],
          'created_at': providerFav['created_at'],
        };
      }

      // Add items to their respective providers
      for (final itemFav in itemFavorites) {
        final item = itemFav['items'] as Map<String, dynamic>;
        final provider = item['providers'] as Map<String, dynamic>;
        final providerId = provider['id'] as String;

        if (!providerMap.containsKey(providerId)) {
          // Provider not favorited, but has favorited items
          providerMap[providerId] = {
            'provider': provider,
            'is_provider_favorited': false,
            'items': [],
            'created_at': itemFav['created_at'],
          };
        }

        providerMap[providerId]!['items'].add({
          'item': item,
          'item_favorite_id': itemFav['id'],
          'created_at': itemFav['created_at'],
        });
      }

      // Convert map to list and sort by most recent favorite
      final favoritesList = providerMap.values.toList();
      favoritesList.sort((a, b) {
        final aDate = DateTime.parse(a['created_at'] as String);
        final bDate = DateTime.parse(b['created_at'] as String);
        return bDate.compareTo(aDate);
      });

      return favoritesList;
    } catch (e) {
      print('Error fetching all favorites: $e');
      return [];
    }
  }

  /// Get total favorites count (items + providers)
  Future<Map<String, int>> getFavoritesCounts(String customerId) async {
    try {
      // Count item favorites
      final itemResponse = await _supabase
          .from('item_favorites')
          .select('id')
          .eq('customer_id', customerId);

      final itemCount = itemResponse is List ? itemResponse.length : 0;

      // Count provider favorites
      final providerResponse = await _supabase
          .from('provider_favorites')
          .select('id')
          .eq('customer_id', customerId);

      final providerCount = providerResponse is List ? providerResponse.length : 0;

      return {
        'items': itemCount,
        'providers': providerCount,
        'total': itemCount + providerCount,
      };
    } catch (e) {
      print('Error getting favorites counts: $e');
      return {'items': 0, 'providers': 0, 'total': 0};
    }
  }

  /// Remove all favorites for a customer (for account deletion, etc.)
  Future<void> clearAllFavorites(String customerId) async {
    try {
      await _supabase
          .from('item_favorites')
          .delete()
          .eq('customer_id', customerId);

      await _supabase
          .from('provider_favorites')
          .delete()
          .eq('customer_id', customerId);
    } catch (e) {
      print('Error clearing all favorites: $e');
      rethrow;
    }
  }
}