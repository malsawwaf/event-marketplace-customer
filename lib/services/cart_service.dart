import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get or create cart for a provider
  Future<String> getOrCreateCart(String customerId, String providerId) async {
    try {
      // Check if cart exists
      final existingCart = await _supabase
          .from('cart')
          .select('id')
          .eq('customer_id', customerId)
          .eq('provider_id', providerId)
          .maybeSingle();

      if (existingCart != null) {
        return existingCart['id'] as String;
      }

      // Create new cart
      final newCart = await _supabase
          .from('cart')
          .insert({
            'customer_id': customerId,
            'provider_id': providerId,
          })
          .select('id')
          .single();

      return newCart['id'] as String;
    } catch (e) {
      print('Error getting/creating cart: $e');
      rethrow;
    }
  }

  /// Add item to cart with stock reservation
  Future<Map<String, dynamic>> addItemToCart({
    required String customerId,
    required String providerId,
    required String itemId,
    required int quantity,
    List<String>? selectedAddonIds,
    String? notes,
  }) async {
    try {
      // Get or create cart
      final cartId = await getOrCreateCart(customerId, providerId);

      // Check if item already exists in cart
      final existingItem = await _supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('cart_id', cartId)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existingItem != null) {
        // Update existing item quantity
        return await updateCartItemQuantity(
          customerId: customerId,
          cartItemId: existingItem['id'] as String,
          newQuantity: (existingItem['quantity'] as int) + quantity,
        );
      }

      // Add new cart item
      final cartItem = await _supabase
          .from('cart_items')
          .insert({
            'cart_id': cartId,
            'item_id': itemId,
            'quantity': quantity,
            'notes': notes,
          })
          .select()
          .single();

      final cartItemId = cartItem['id'] as String;

      // Create stock reservation
      await _createStockReservation(
        customerId: customerId,
        itemId: itemId,
        cartItemId: cartItemId,
        quantity: quantity,
      );

      // Add selected add-ons
      if (selectedAddonIds != null && selectedAddonIds.isNotEmpty) {
        await _addCartItemAddons(cartItemId, selectedAddonIds);
      }

      return cartItem;
    } catch (e) {
      print('Error adding item to cart: $e');
      rethrow;
    }
  }

  /// Create stock reservation
  Future<void> _createStockReservation({
    required String customerId,
    required String itemId,
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await _supabase.from('stock_reservations').insert({
        'customer_id': customerId,
        'item_id': itemId,
        'cart_item_id': cartItemId,
        'quantity': quantity,
        'expires_at': expiresAt.toIso8601String(),
        'status': 'active',
      });
    } catch (e) {
      print('Error creating stock reservation: $e');
      rethrow;
    }
  }

  /// Add add-ons to cart item
  Future<void> _addCartItemAddons(
    String cartItemId,
    List<String> addonIds,
  ) async {
    try {
      // Fetch addon details
      final addons = await _supabase
          .from('item_addons')
          .select('id, name, additional_price')
          .inFilter('id', addonIds);

      if (addons is List && addons.isNotEmpty) {
        final addonInserts = addons.map((addon) => {
              'cart_item_id': cartItemId,
              'item_addon_id': addon['id'],
              'addon_name': addon['name'],
              'additional_price': addon['additional_price'],
            }).toList();

        await _supabase.from('cart_item_addons').insert(addonInserts);
      }
    } catch (e) {
      print('Error adding cart item add-ons: $e');
      rethrow;
    }
  }

  /// Update cart item quantity (and update reservation)
  Future<Map<String, dynamic>> updateCartItemQuantity({
    required String customerId,
    required String cartItemId,
    required int newQuantity,
  }) async {
    try {
      // Get cart item details
      final cartItem = await _supabase
          .from('cart_items')
          .select('item_id, quantity')
          .eq('id', cartItemId)
          .single();

      final itemId = cartItem['item_id'] as String;

      // Update cart item quantity
      final updatedItem = await _supabase
          .from('cart_items')
          .update({
            'quantity': newQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cartItemId)
          .select()
          .single();

      // Update stock reservation
      await _updateStockReservation(
        cartItemId: cartItemId,
        itemId: itemId,
        newQuantity: newQuantity,
      );

      return updatedItem;
    } catch (e) {
      print('Error updating cart item quantity: $e');
      rethrow;
    }
  }

  /// Update stock reservation quantity
  Future<void> _updateStockReservation({
    required String cartItemId,
    required String itemId,
    required int newQuantity,
  }) async {
    try {
      // Reset expiry time to 10 minutes from now
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await _supabase
          .from('stock_reservations')
          .update({
            'quantity': newQuantity,
            'expires_at': expiresAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('cart_item_id', cartItemId)
          .eq('status', 'active');
    } catch (e) {
      print('Error updating stock reservation: $e');
      rethrow;
    }
  }

  /// Remove item from cart (cancel reservation)
  Future<void> removeItemFromCart(String cartItemId) async {
    try {
      // Cancel stock reservation
      await _supabase
          .from('stock_reservations')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('cart_item_id', cartItemId)
          .eq('status', 'active');

      // Delete cart item add-ons
      await _supabase
          .from('cart_item_addons')
          .delete()
          .eq('cart_item_id', cartItemId);

      // Delete cart item
      await _supabase.from('cart_items').delete().eq('id', cartItemId);
    } catch (e) {
      print('Error removing item from cart: $e');
      rethrow;
    }
  }

  /// Get customer's cart with all items, add-ons, and provider details
  Future<List<Map<String, dynamic>>> getCustomerCarts(String customerId) async {
    try {
      final carts = await _supabase
          .from('cart')
          .select('''
            id,
            provider_id,
            created_at,
            providers!inner(
              id,
              company_name_en,
              company_name_ar,
              profile_photo_url,
              store_location,
              price_range
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      if (carts is! List || carts.isEmpty) {
        return [];
      }

      // Fetch cart items for each cart
      List<Map<String, dynamic>> cartsWithItems = [];

      for (final cart in carts) {
        final cartData = Map<String, dynamic>.from(cart);
        final cartId = cartData['id'] as String;

        // Get cart items with item details, add-ons, and reservations
        final items = await _supabase
            .from('cart_items')
            .select('''
              id,
              item_id,
              quantity,
              notes,
              event_date,
              event_start_date,
              event_end_date,
              event_time,
              created_at,
              items!inner(
                id,
                name,
                price,
                pricing_type,
                photo_urls,
                stock_quantity,
                min_order_quantity,
                max_order_quantity
              )
            ''')
            .eq('cart_id', cartId);

        if (items is List && items.isNotEmpty) {
          // Fetch add-ons and reservations for each item
          for (var i = 0; i < items.length; i++) {
            final itemData = Map<String, dynamic>.from(items[i]);
            final cartItemId = itemData['id'] as String;

            // Get add-ons
            final addons = await _supabase
                .from('cart_item_addons')
                .select()
                .eq('cart_item_id', cartItemId);

            itemData['addons'] = addons is List ? addons : [];

            // Get reservation status
            final reservation = await _supabase
                .from('stock_reservations')
                .select('expires_at, status')
                .eq('cart_item_id', cartItemId)
                .eq('status', 'active')
                .maybeSingle();

            itemData['reservation'] = reservation;

            items[i] = itemData;
          }

          cartData['items'] = items;
          cartsWithItems.add(cartData);
        }
      }

      return cartsWithItems;
    } catch (e) {
      print('Error getting customer carts: $e');
      return [];
    }
  }

  /// Calculate cart totals
  Map<String, double> calculateCartTotals({
    required List<Map<String, dynamic>> cartItems,
    double deliveryFee = 0,
    double discountAmount = 0,
  }) {
    double subtotal = 0;

    for (final cartItem in cartItems) {
      final item = cartItem['items'] as Map<String, dynamic>;
      final quantity = cartItem['quantity'] as int;
      final price = (item['price'] as num).toDouble();

      // Calculate item price (base price only for per_day - final price in checkout)
      double itemPrice = price * quantity;

      // Add add-ons price (base price)
      final addons = cartItem['addons'] as List<dynamic>?;
      if (addons != null && addons.isNotEmpty) {
        for (final addon in addons) {
          final addonPrice = (addon['additional_price'] as num).toDouble();
          itemPrice += addonPrice * quantity;
        }
      }

      subtotal += itemPrice;
    }

    final vatAmount = subtotal * 0.15; // 15% VAT
    final total = subtotal + vatAmount + deliveryFee - discountAmount;

    return {
      'subtotal': subtotal,
      'vat': vatAmount,
      'delivery_fee': deliveryFee,
      'discount': discountAmount,
      'total': total,
    };
  }

  /// Clear expired items from cart
  Future<List<String>> clearExpiredItems(String customerId) async {
    try {
      // Get expired reservations
      final expiredReservations = await _supabase
          .from('stock_reservations')
          .select('cart_item_id')
          .eq('customer_id', customerId)
          .eq('status', 'expired');

      if (expiredReservations is! List || expiredReservations.isEmpty) {
        return [];
      }

      final expiredCartItemIds = expiredReservations
          .map((r) => r['cart_item_id'] as String)
          .toList();

      // Remove expired cart items
      for (final cartItemId in expiredCartItemIds) {
        await removeItemFromCart(cartItemId);
      }

      return expiredCartItemIds;
    } catch (e) {
      print('Error clearing expired items: $e');
      return [];
    }
  }

  /// Get cart item count for a customer
  Future<int> getCartItemCount(String customerId) async {
    try {
      final carts = await _supabase
          .from('cart')
          .select('id')
          .eq('customer_id', customerId);

      if (carts is! List || carts.isEmpty) {
        return 0;
      }

      int totalCount = 0;
      for (final cart in carts) {
        final cartId = cart['id'] as String;
        
        final items = await _supabase
            .from('cart_items')
            .select('id')
            .eq('cart_id', cartId);

        if (items is List) {
          totalCount += items.length;
        }
      }

      return totalCount;
    } catch (e) {
      print('Error getting cart item count: $e');
      return 0;
    }
  }

  /// Clear entire cart for a provider
  Future<void> clearCart(String cartId) async {
    try {
      // Get all cart items
      final cartItems = await _supabase
          .from('cart_items')
          .select('id')
          .eq('cart_id', cartId);

      if (cartItems is List && cartItems.isNotEmpty) {
        for (final item in cartItems) {
          await removeItemFromCart(item['id'] as String);
        }
      }

      // Delete the cart itself
      await _supabase.from('cart').delete().eq('id', cartId);
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }
}