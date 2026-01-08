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
      print('🔍 Fetching item favorites for customer: $customerId');

      final response = await _supabase
          .from('item_favorites')
          .select('''
            id,
            created_at,
            items!item_favorites_item_id_fkey(
              id,
              name,
              name_ar,
              price,
              pricing_type,
              photo_url,
              stock_quantity,
              category_id,
              provider_id,
              providers(
                id,
                company_name_en,
                trading_name,
                profile_photo_url,
                store_location,
                price_range,
                average_rating
              )
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      print('📦 Raw item favorites response: $response');

      // Filter out items where the item or provider data is null (deleted items)
      final validItems = response.where((item) {
        final itemData = item['items'];
        if (itemData == null) {
          print('⚠️ Skipping favorite with null item data: ${item['id']}');
          return false;
        }
        final providerData = itemData['providers'];
        if (providerData == null) {
          print('⚠️ Skipping favorite with null provider data for item: ${itemData['id']}');
          return false;
        }
        return true;
      }).toList();

      print('✅ Valid item favorites: ${validItems.length} out of ${response.length}');
      return validItems.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('❌ Error fetching item favorites: $e');
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

      return response.map((item) => item['item_id'] as String).toSet();
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
      print('🔍 Fetching provider favorites for customer: $customerId');

      final response = await _supabase
          .from('provider_favorites')
          .select('''
            id,
            created_at,
            providers!provider_favorites_provider_id_fkey(
              id,
              company_name_en,
              trading_name,
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

      print('📦 Raw provider favorites response: $response');
      print('📦 Response type: ${response.runtimeType}');
      print('📦 Response length: ${response.length}');

      if (response.isEmpty) {
        print('⚠️ Provider favorites response is empty');
        return [];
      }

      // Log each item for debugging
      for (var i = 0; i < response.length; i++) {
        print('📦 Item $i: ${response[i]}');
      }

      // Filter out providers where the provider data is null (deleted providers)
      final validProviders = response.where((item) {
        final providerData = item['providers'];
        if (providerData == null) {
          print('⚠️ Skipping favorite with null provider data: ${item['id']}');
          return false;
        }
        return true;
      }).toList();

      print('✅ Valid provider favorites: ${validProviders.length} out of ${response.length}');
      return validProviders.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('❌ Error fetching provider favorites: $e');
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

      return response.map((item) => item['provider_id'] as String).toSet();
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
      print('🔍 Getting ALL favorites (combined view) for customer: $customerId');

      // Get favorited providers
      final providerFavorites = await getProviderFavorites(customerId);
      print('📊 Provider favorites count: ${providerFavorites.length}');

      // Get favorited items
      final itemFavorites = await getItemFavorites(customerId);
      print('📊 Item favorites count: ${itemFavorites.length}');

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

      print('✅ Combined favorites: ${favoritesList.length} provider groups');
      for (var i = 0; i < favoritesList.length; i++) {
        final group = favoritesList[i];
        final provider = group['provider'] as Map<String, dynamic>;
        final items = group['items'] as List;
        print('   ${i + 1}. ${provider['company_name_en']} - ${items.length} items, is_favorited: ${group['is_provider_favorited']}');
      }

      return favoritesList;
    } catch (e) {
      print('❌ Error fetching all favorites: $e');
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

      final itemCount = itemResponse.length;

      // Count provider favorites
      final providerResponse = await _supabase
          .from('provider_favorites')
          .select('id')
          .eq('customer_id', customerId);

      final providerCount = providerResponse.length;

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