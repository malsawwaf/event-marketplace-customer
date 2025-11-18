import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../services/orders_service.dart';
import '../../services/reviews_service.dart';
import '../../config/app_theme.dart';
import 'order_detail_screen.dart';
import 'submit_review_screen.dart';
import 'dart:async';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({Key? key}) : super(key: key);

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _ordersService = OrdersService();
  final _reviewsService = ReviewsService();

  late TabController _tabController;
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = true;
  RealtimeChannel? _ordersChannel;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
    _setupRealtimeSubscription();
    _startTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ordersChannel?.unsubscribe();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Update UI every minute to refresh acceptance timers
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadOrders() async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    setState(() => _isLoading = true);

    try {
      final orders = await _ordersService.getCustomerOrders(customerId);
      if (mounted) {
        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  void _setupRealtimeSubscription() {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    _ordersChannel = _ordersService.subscribeToOrderUpdates(
      customerId,
      (orderUpdate) {
        if (mounted) {
          _loadOrders();
        }
      },
    );
  }

  List<Map<String, dynamic>> _filterOrdersByStatus(String filter) {
    switch (filter) {
      case 'active':
        return _allOrders
            .where((o) => ['pending', 'accepted', 'preparing', 'ready', 'dispatched']
                .contains(o['status']))
            .toList();
      case 'delivered':
        return _allOrders.where((o) => o['status'] == 'delivered').toList();
      case 'cancelled':
        return _allOrders
            .where((o) => ['cancelled', 'rejected'].contains(o['status']))
            .toList();
      case 'pending':
        return _allOrders.where((o) => o['status'] == 'pending').toList();
      default:
        return _allOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myOrders),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.secondaryCoral,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: [
            Tab(text: '${l10n.myOrders} (${_allOrders.length})'),
            Tab(
              text: '${l10n.activeOrders} (${_filterOrdersByStatus('active').length})',
            ),
            Tab(
              text: '${l10n.pending} (${_filterOrdersByStatus('pending').length})',
            ),
            Tab(
              text: '${l10n.delivered} (${_filterOrdersByStatus('delivered').length})',
            ),
            Tab(
              text: '${l10n.cancelled} (${_filterOrdersByStatus('cancelled').length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy))
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: AppTheme.primaryNavy,
                  child: _buildOrdersList(_allOrders),
                ),
                RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: AppTheme.primaryNavy,
                  child: _buildOrdersList(_filterOrdersByStatus('active')),
                ),
                RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: AppTheme.primaryNavy,
                  child: _buildOrdersList(_filterOrdersByStatus('pending')),
                ),
                RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: AppTheme.primaryNavy,
                  child: _buildOrdersList(_filterOrdersByStatus('delivered')),
                ),
                RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: AppTheme.primaryNavy,
                  child: _buildOrdersList(_filterOrdersByStatus('cancelled')),
                ),
              ],
            ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders) {
    final l10n = AppLocalizations.of(context)!;

    if (orders.isEmpty) {
      return ListView(
        key: const ValueKey('empty_orders'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noOrders,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.myOrders,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      key: ValueKey('orders_${orders.length}'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;
    final orderId = order['id'] as String;
    final orderNumber = order['order_number'] as String;
    final status = order['status'] as String;
    final totalAmount = (order['total_amount'] as num).toDouble();
    final createdAt = DateTime.parse(order['created_at']);
    final provider = order['providers'] as Map<String, dynamic>;
    final orderItems = order['order_items'] as List;

    final acceptanceDeadline = order['acceptance_deadline'] != null
        ? DateTime.parse(order['acceptance_deadline'])
        : null;

    final timeRemaining = acceptanceDeadline != null
        ? _ordersService.getAcceptanceTimeRemaining(acceptanceDeadline)
        : null;

    final canCancel = _ordersService.canCancelOrder(status, acceptanceDeadline);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: orderId),
            ),
          );
          // If result is true, it means order was cancelled or updated
          if (result == true && mounted) {
            _loadOrders();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _ordersService.formatOrderDate(context, createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: provider['profile_photo_url'] != null
                        ? NetworkImage(provider['profile_photo_url'])
                        : null,
                    child: provider['profile_photo_url'] == null
                        ? const Icon(Icons.business, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic && provider['trading_name_ar'] != null
                              ? provider['trading_name_ar'] as String
                              : provider['company_name_en'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${orderItems.length} ${l10n.items}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${totalAmount.toStringAsFixed(2)} ﷼',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ],
              ),
              if (status == 'pending' && timeRemaining != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          timeRemaining.inMinutes > 0
                              ? '${l10n.processing2} ${timeRemaining.inMinutes}m'
                              : l10n.waitingForProviderResponse,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (canCancel) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(orderId),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(l10n.cancelOrder),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
              if (status == 'delivered') ...[
                const SizedBox(height: 12),
                FutureBuilder<bool>(
                  future: _reviewsService.hasReviewedOrder(orderId, _supabase.auth.currentUser!.id),
                  builder: (context, snapshot) {
                    // If already reviewed, don't show button
                    if (snapshot.hasData && snapshot.data == true) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'You reviewed this order',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // If not reviewed, show button
                    if (snapshot.hasData && snapshot.data == false) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubmitReviewScreen(
                                  orderId: orderId,
                                  order: order,
                                ),
                              ),
                            );
                            // Refresh if review was submitted
                            if (result == true && mounted) {
                              setState(() {}); // Trigger rebuild to hide button
                            }
                          },
                          icon: const Icon(Icons.rate_review, size: 18),
                          label: Text(l10n.writeReview),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNavy,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      );
                    }
                    
                    // Loading state
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colorName = _ordersService.getOrderStatusColor(status);
    final label = _ordersService.getOrderStatusLabel(context, status);

    Color backgroundColor;
    Color textColor;
    
    switch (colorName) {
      case 'orange':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade700;
        break;
      case 'blue':
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue.shade700;
        break;
      case 'purple':
        backgroundColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple.shade700;
        break;
      case 'teal':
        backgroundColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal.shade700;
        break;
      case 'indigo':
        backgroundColor = Colors.indigo.withOpacity(0.1);
        textColor = Colors.indigo.shade700;
        break;
      case 'green':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade700;
        break;
      case 'red':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade700;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCancelDialog(String orderId) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelOrder),
        content: Text(l10n.cancelOrder),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.cancelOrder),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      await _ordersService.cancelOrder(orderId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.cancelOrder} ${l10n.success.toLowerCase()}'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the orders list
        await _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}