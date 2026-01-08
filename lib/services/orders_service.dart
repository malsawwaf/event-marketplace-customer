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
                photo_url
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
                photo_url
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
                photo_url,
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
  /// Uses safe_update_order_status RPC for atomic operation and race condition prevention
  Future<void> cancelOrder(String orderId) async {
    try {
      // Get order details before cancelling for notification
      final orderData = await _supabase
          .from('orders')
          .select('provider_id, order_number, total_amount, providers(user_id)')
          .eq('id', orderId)
          .single();

      // Use the safe RPC function that handles:
      // - Atomic row locking (prevents race conditions)
      // - Status validation (only pending orders can be cancelled)
      // - Single stock return (prevents duplicate stock returns)
      // - Payment status update
      final result = await _supabase.rpc('safe_update_order_status', params: {
        'p_order_id': orderId,
        'p_new_status': 'cancelled',
        'p_actor_type': 'customer',
      });

      // Check if the operation was successful
      if (result is Map && result['success'] == false) {
        throw Exception(result['error'] ?? 'Failed to cancel order');
      }

      // Send notification to provider about cancelled order
      await _sendOrderCancelledNotification(
        providerUserId: orderData['providers']?['user_id'] as String?,
        orderId: orderId,
        orderNumber: orderData['order_number'] as String,
        totalAmount: (orderData['total_amount'] as num).toDouble(),
      );
    } catch (e) {
      // If the RPC function doesn't exist yet, fall back to the old method
      if (e.toString().contains('function') && e.toString().contains('does not exist')) {
        await _cancelOrderLegacy(orderId);
      } else {
        throw Exception('Failed to cancel order: $e');
      }
    }
  }

  /// Send push notification to provider about order cancellation
  Future<void> _sendOrderCancelledNotification({
    required String? providerUserId,
    required String orderId,
    required String orderNumber,
    required double totalAmount,
  }) async {
    if (providerUserId == null) return;

    try {
      // Get customer name
      final customerId = _supabase.auth.currentUser?.id;
      String customerName = 'Customer';

      if (customerId != null) {
        final customerData = await _supabase
            .from('customers')
            .select('first_name, last_name')
            .eq('id', customerId)
            .maybeSingle();

        if (customerData != null) {
          customerName = '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'.trim();
          if (customerName.isEmpty) customerName = 'Customer';
        }
      }

      // Call the Edge Function to send push notification
      await _supabase.functions.invoke('send-push-notification', body: {
        'user_id': providerUserId,
        'user_type': 'provider',
        'title_en': 'Order Cancelled ❌',
        'title_ar': 'تم إلغاء الطلب ❌',
        'body_en': '$customerName cancelled order $orderNumber (${totalAmount.toStringAsFixed(2)} SAR)',
        'body_ar': '$customerName ألغى الطلب $orderNumber (${totalAmount.toStringAsFixed(2)} ر.س)',
        'notification_type': 'order_cancelled',
        'data': {
          'order_id': orderId,
          'order_number': orderNumber,
          'customer_name': customerName,
          'total_amount': totalAmount.toString(),
        },
      });

      print('📱 Push notification sent to provider about cancelled order $orderNumber');
    } catch (e) {
      // Don't fail the cancellation if notification fails
      print('⚠️ Error sending cancellation notification: $e');
    }
  }

  /// Legacy cancel order method (fallback if RPC function not available)
  Future<void> _cancelOrderLegacy(String orderId) async {
    // First check current status to prevent race conditions
    final order = await _supabase
        .from('orders')
        .select('status, order_items(item_id, quantity)')
        .eq('id', orderId)
        .single();

    final currentStatus = order['status'] as String;

    // Validate status - must be pending
    if (currentStatus != 'pending') {
      throw Exception('Order is no longer pending. Current status: $currentStatus');
    }

    // Return stock for all items
    final orderItems = order['order_items'] as List;
    for (final item in orderItems) {
      await _supabase.rpc('return_stock', params: {
        'p_item_id': item['item_id'],
        'p_quantity': item['quantity'],
      });
    }

    // Update order status - use conditional update for race protection
    // Only update if status is still 'pending'
    final result = await _supabase
        .from('orders')
        .update({
          'status': 'cancelled',
          'payment_status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId)
        .eq('status', 'pending') // Only update if still pending
        .select('id');

    // Check if the update was successful
    if (result.isEmpty) {
      throw Exception('Order was already processed by another action');
    }
  }

  /// Subscribe to real-time order updates (INSERT, UPDATE, DELETE)
  RealtimeChannel subscribeToOrderUpdates(
    String customerId,
    Function(Map<String, dynamic>) onOrderUpdate,
  ) {
    final channel = _supabase
        .channel('customer_orders_$customerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: customerId,
          ),
          callback: (payload) {
            print('🔵 Realtime: New order inserted');
            onOrderUpdate(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: customerId,
          ),
          callback: (payload) {
            print('🔵 Realtime: Order updated');
            onOrderUpdate(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: customerId,
          ),
          callback: (payload) {
            print('🔵 Realtime: Order deleted');
            onOrderUpdate(payload.oldRecord);
          },
        )
        .subscribe((status, [error]) {
          print('🔵 Realtime subscription status: $status');
          if (error != null) {
            print('❌ Realtime error: $error');
          }
        });

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
                photo_url
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

    // Compare in UTC to avoid timezone issues
    final now = DateTime.now().toUtc();
    final deadlineUtc = acceptanceDeadline.toUtc();
    final remaining = deadlineUtc.difference(now);

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