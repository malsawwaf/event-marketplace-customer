import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';

class OrdersService {
  final _supabase = Supabase.instance.client;

  /// Get all orders for a customer
  Future<List<Map<String, dynamic>>> getCustomerOrders(String customerId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            providers (
              id,
              company_name_en,
              trading_name,
              profile_photo_url,
              mobile
            ),
            order_items (
              *,
              items (
                id,
                name,
                name_ar,
                category_id,
                photo_urls
              ),
              order_item_addons (*)
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  /// Get orders filtered by status
  Future<List<Map<String, dynamic>>> getOrdersByStatus(
    String customerId,
    String status,
  ) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            providers (
              id,
              company_name_en,
              trading_name,
              profile_photo_url,
              mobile
            ),
            order_items (
              *,
              items (
                id,
                name,
                name_ar,
                category_id,
                photo_urls
              ),
              order_item_addons (*)
            )
          ''')
          .eq('customer_id', customerId)
          .eq('status', status)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  /// Get a single order by ID
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            providers (
              id,
              company_name_en,
              trading_name,
              profile_photo_url,
              mobile,
              store_location
            ),
            order_items (
              *,
              items (
                id,
                name,
                name_ar,
                category_id,
                photo_urls,
                pricing_type
              ),
              order_item_addons (*)
            )
          ''')
          .eq('id', orderId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to load order: $e');
    }
  }

  /// Cancel an order (only if status is 'pending')
  Future<void> cancelOrder(String orderId) async {
    try {
      // First check if order is pending
      final order = await _supabase
          .from('orders')
          .select('status, order_items(item_id, quantity)')
          .eq('id', orderId)
          .single();

      if (order['status'] != 'pending') {
        throw Exception('Only pending orders can be cancelled');
      }

      // Return stock for all items
      final orderItems = order['order_items'] as List;
      for (final item in orderItems) {
        await _supabase.rpc('return_stock', params: {
          'p_item_id': item['item_id'],
          'p_quantity': item['quantity'],
        });
      }

      // Update order status
      await _supabase
          .from('orders')
          .update({
            'status': 'cancelled',
			'payment_status': 'cancelled',  // ✅ Add this line
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// Subscribe to real-time order updates
  RealtimeChannel subscribeToOrderUpdates(
    String customerId,
    Function(Map<String, dynamic>) onOrderUpdate,
  ) {
    final channel = _supabase
        .channel('customer_orders_$customerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: customerId,
          ),
          callback: (payload) {
            onOrderUpdate(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Check if order can be cancelled
  bool canCancelOrder(String status, DateTime? acceptanceDeadline) {
    if (status != 'pending') return false;
    if (acceptanceDeadline == null) return true;
    
    final now = DateTime.now();
    return now.isBefore(acceptanceDeadline);
  }

  /// Get order status color
  String getOrderStatusColor(String status) {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'accepted':
        return 'blue';
      case 'preparing':
        return 'purple';
      case 'ready':
        return 'teal';
      case 'dispatched':
        return 'indigo';
      case 'delivered':
        return 'green';
      case 'cancelled':
        return 'red';
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get order status label
  String getOrderStatusLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 'pending':
        return l10n.pendingAcceptance;
      case 'accepted':
        return l10n.accepted;
      case 'preparing':
        return l10n.preparing;
      case 'ready':
        return l10n.ready;
      case 'dispatched':
        return l10n.onTheWay;
      case 'delivered':
        return l10n.delivered;
      case 'cancelled':
        return l10n.cancelled;
      case 'rejected':
        return l10n.rejected;
      default:
        return l10n.unknown;
    }
  }

  /// Check if order can be reviewed
  bool canReviewOrder(String status) {
    return status == 'delivered';
  }

  /// Get orders that can be reviewed (delivered orders without reviews)
  Future<List<Map<String, dynamic>>> getOrdersNeedingReview(
    String customerId,
  ) async {
    try {
      // Get delivered orders
      final orders = await _supabase
          .from('orders')
          .select('''
            *,
            providers (
              id,
              company_name_en,
              trading_name,
              profile_photo_url
            ),
            order_items (
              *,
              items (
                id,
                name,
                name_ar,
                photo_urls
              )
            )
          ''')
          .eq('customer_id', customerId)
          .eq('status', 'delivered')
          .order('created_at', ascending: false);

      // Filter out orders that already have reviews
      final List<Map<String, dynamic>> ordersNeedingReview = [];
      
      for (final order in orders) {
        final orderId = order['id'] as String;
        
        // Check if this order has been reviewed
        final reviewCheck = await _supabase
            .from('reviews')
            .select('id')
            .eq('order_id', orderId)
            .maybeSingle();

        if (reviewCheck == null) {
          ordersNeedingReview.add(order);
        }
      }

      return ordersNeedingReview;
    } catch (e) {
      throw Exception('Failed to load orders needing review: $e');
    }
  }

  /// Calculate time remaining for acceptance
  Duration? getAcceptanceTimeRemaining(DateTime? acceptanceDeadline) {
    if (acceptanceDeadline == null) return null;
    
    final now = DateTime.now();
    final remaining = acceptanceDeadline.difference(now);
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Format order date
  String formatOrderDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} ${l10n.minutesAgo}';
      }
      return '${difference.inHours} ${l10n.hoursAgo}';
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${l10n.daysAgo}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}