import 'package:supabase_flutter/supabase_flutter.dart';

class StockService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check available stock for an item (actual stock - active reservations)
  /// Returns the real-time available quantity
  Future<int> getAvailableStock(String itemId) async {
    try {
      final response = await _supabase.rpc(
        'get_available_stock',
        params: {'p_item_id': itemId},
      );

      return response as int;
    } catch (e) {
      print('Error getting available stock: $e');
      rethrow;
    }
  }

  /// Check if requested quantity is available for an item
  /// Returns true if stock is available, false otherwise
  Future<bool> isStockAvailable(String itemId, int requestedQuantity) async {
    try {
      final availableStock = await getAvailableStock(itemId);
      return availableStock >= requestedQuantity;
    } catch (e) {
      print('Error checking stock availability: $e');
      return false;
    }
  }

  /// Get item's total stock quantity (from items table)
  Future<int> getTotalStock(String itemId) async {
    try {
      final response = await _supabase
          .from('items')
          .select('stock_quantity')
          .eq('id', itemId)
          .single();

      return response['stock_quantity'] as int;
    } catch (e) {
      print('Error getting total stock: $e');
      rethrow;
    }
  }

  /// Get active reservations for an item (for debugging/admin purposes)
  Future<List<Map<String, dynamic>>> getActiveReservations(String itemId) async {
    try {
      final response = await _supabase
          .from('stock_reservations')
          .select()
          .eq('item_id', itemId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      if (response is List) {
        return response.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting active reservations: $e');
      return [];
    }
  }

  /// Validate stock before cart operations
  /// Throws exception with user-friendly message if stock is insufficient
  Future<void> validateStockForCart({
    required String itemId,
    required int requestedQuantity,
    String? excludeCartItemId, // For updates, exclude current cart item's reservation
  }) async {
    try {
      // Get available stock
      int availableStock = await getAvailableStock(itemId);

      // If updating existing cart item, add back its current reservation
      if (excludeCartItemId != null) {
        final currentReservation = await _getCurrentReservation(excludeCartItemId);
        if (currentReservation != null) {
          availableStock += currentReservation['quantity'] as int;
        }
      }

      if (availableStock < requestedQuantity) {
        throw Exception(
          'Insufficient stock. Only $availableStock items available.',
        );
      }
    } catch (e) {
      if (e.toString().contains('Insufficient stock')) {
        rethrow;
      }
      print('Error validating stock: $e');
      throw Exception('Unable to check stock availability. Please try again.');
    }
  }

  /// Get current reservation for a cart item (helper method)
  Future<Map<String, dynamic>?> _getCurrentReservation(String cartItemId) async {
    try {
      final response = await _supabase
          .from('stock_reservations')
          .select()
          .eq('cart_item_id', cartItemId)
          .eq('status', 'active')
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting current reservation: $e');
      return null;
    }
  }

  /// Check if any items in a list have insufficient stock
  /// Returns map of itemId -> available stock for items with issues
  Future<Map<String, int>> checkMultipleItems(
    List<Map<String, dynamic>> items,
  ) async {
    final insufficientStock = <String, int>{};

    for (final item in items) {
      final itemId = item['itemId'] as String;
      final requestedQty = item['quantity'] as int;

      final availableStock = await getAvailableStock(itemId);
      if (availableStock < requestedQty) {
        insufficientStock[itemId] = availableStock;
      }
    }

    return insufficientStock;
  }
}