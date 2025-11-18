import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../services/orders_service.dart';
import '../../services/reviews_service.dart';
import '../../config/app_theme.dart';
import 'submit_review_screen.dart';
import 'dart:async';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _supabase = Supabase.instance.client;
  final _ordersService = OrdersService();
  final _reviewsService = ReviewsService();

  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _isCancelling = false;
  RealtimeChannel? _orderChannel;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    _setupRealtimeSubscription();
    _startTimer();
  }

  @override
  void dispose() {
    _orderChannel?.unsubscribe();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);

    try {
      final order = await _ordersService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
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

    _orderChannel = _ordersService.subscribeToOrderUpdates(
      customerId,
      (orderUpdate) {
        if (mounted && orderUpdate['id'] == widget.orderId) {
          _loadOrderDetails();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.orderDetails),
          backgroundColor: AppTheme.primaryNavy,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy)),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.orderDetails),
          backgroundColor: AppTheme.primaryNavy,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(l10n.error)),
      );
    }

    final status = _order!['status'] as String;
    final orderNumber = _order!['order_number'] as String;
    final provider = _order!['providers'] as Map<String, dynamic>;
    final orderItems = _order!['order_items'] as List;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final acceptanceDeadline = _order!['acceptance_deadline'] != null
        ? DateTime.parse(_order!['acceptance_deadline'])
        : null;

    final canCancel = _ordersService.canCancelOrder(status, acceptanceDeadline);

    return Scaffold(
      appBar: AppBar(
        title: Text(orderNumber),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          if (canCancel)
            IconButton(
              onPressed: _showCancelDialog,
              icon: const Icon(Icons.cancel_outlined),
              tooltip: l10n.cancelOrder,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrderDetails,
        color: AppTheme.primaryNavy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusTimeline(),
              const SizedBox(height: 24),
              _buildProviderSection(provider),
              const SizedBox(height: 16),
              _buildDeliverySection(),
              const SizedBox(height: 16),
              _buildOrderItemsSection(orderItems),
              const SizedBox(height: 16),
              _buildPricingBreakdown(),
              const SizedBox(height: 16),
              _buildPaymentSection(),
              if (canCancel) ...[
                const SizedBox(height: 24),
                _buildCancelButton(),
              ],
              if (status == 'delivered' && _ordersService.canReviewOrder(status)) ...[
                const SizedBox(height: 24),
                _buildReviewButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final l10n = AppLocalizations.of(context)!;
    final status = _order!['status'] as String;
    final createdAt = DateTime.parse(_order!['created_at']);

    final acceptanceDeadline = _order!['acceptance_deadline'] != null
        ? DateTime.parse(_order!['acceptance_deadline'])
        : null;

    final timeRemaining = acceptanceDeadline != null
        ? _ordersService.getAcceptanceTimeRemaining(acceptanceDeadline)
        : null;

    final statuses = [
      {'key': 'pending', 'label': l10n.orderPlaced, 'icon': Icons.shopping_cart},
      {'key': 'accepted', 'label': l10n.accepted, 'icon': Icons.check_circle},
      {'key': 'preparing', 'label': l10n.preparing, 'icon': Icons.inventory},
      {'key': 'ready', 'label': l10n.ready, 'icon': Icons.done_all},
      {'key': 'dispatched', 'label': l10n.dispatched, 'icon': Icons.local_shipping},
      {'key': 'delivered', 'label': l10n.delivered, 'icon': Icons.home},
    ];

    final currentIndex = statuses.indexWhere((s) => s['key'] == status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.orderStatus,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _ordersService.getOrderStatusLabel(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (status == 'pending' && timeRemaining != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.waitingForProviderResponse,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeRemaining.inMinutes > 0
                                ? '${l10n.timeRemaining}: ${timeRemaining.inMinutes}m ${timeRemaining.inSeconds % 60}s'
                                : 'Processing...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ...statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final statusData = entry.value;
              final isActive = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final isLast = index == statuses.length - 1;

              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _getStatusColor(status)
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statusData['icon'] as IconData,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusData['label'] as String,
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive ? Colors.black : Colors.grey,
                              ),
                            ),
                            if (index == 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                _ordersService.formatOrderDate(createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.only(left: 19),
                      width: 2,
                      height: 30,
                      color: isActive ? _getStatusColor(status) : Colors.grey[300],
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSection(Map<String, dynamic> provider) {
    final l10n = AppLocalizations.of(context)!;
    final companyName = provider['company_name_en'] as String;
    final photoUrl = provider['profile_photo_url'] as String?;
    final mobile = provider['mobile'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.providerInformation,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.business, size: 30) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (mobile != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              mobile,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
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
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    final l10n = AppLocalizations.of(context)!;
    final deliveryAddress = _order!['delivery_address'] as String;
    final eventDate = _order!['event_date'] != null
        ? DateTime.parse(_order!['event_date'])
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deliveryInformationTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryNavy),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deliveryAddress,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (eventDate != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.event, color: AppTheme.primaryNavy),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.eventDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${eventDate.day}/${eventDate.month}/${eventDate.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection(List<dynamic> orderItems) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.orderItems} (${orderItems.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...orderItems.map((orderItem) {
              final item = orderItem['items'] as Map<String, dynamic>;
              final quantity = orderItem['quantity'] as int;
              final unitPrice = (orderItem['unit_price'] as num).toDouble();
              final subtotal = (orderItem['subtotal'] as num).toDouble();
              final addons = orderItem['order_item_addons'] as List?;
              
              final itemName = item['name'] as String;
              final photoUrls = item['photo_urls'] as List?;
              final photoUrl = photoUrls?.isNotEmpty == true ? photoUrls![0] : null;

              final eventDate = orderItem['event_date'] != null
                  ? DateTime.parse(orderItem['event_date'])
                  : null;
              final eventStartDate = orderItem['event_start_date'] != null
                  ? DateTime.parse(orderItem['event_start_date'])
                  : null;
              final eventEndDate = orderItem['event_end_date'] != null
                  ? DateTime.parse(orderItem['event_end_date'])
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (photoUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photoUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                );
                              },
                            ),
                          ),
                        if (photoUrl != null) const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${unitPrice.toStringAsFixed(2)} SAR × $quantity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${subtotal.toStringAsFixed(2)} SAR',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (addons != null && addons.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.addons}:',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...addons.map((addon) {
                        final addonName = addon['addon_name'] as String;
                        final addonPrice = (addon['addon_price'] as num).toDouble();
                        return Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '+ $addonName',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${addonPrice.toStringAsFixed(2)} SAR',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (eventDate != null || (eventStartDate != null && eventEndDate != null)) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            eventDate != null
                                ? 'Event: ${eventDate.day}/${eventDate.month}/${eventDate.year}'
                                : 'Event: ${eventStartDate!.day}/${eventStartDate.month} - ${eventEndDate!.day}/${eventEndDate.month}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    final l10n = AppLocalizations.of(context)!;
    final subtotal = (_order!['subtotal'] as num).toDouble();
    final vatAmount = (_order!['vat_amount'] as num).toDouble();
    final deliveryFee = (_order!['delivery_fee'] as num).toDouble();
    final discountAmount = (_order!['discount_amount'] as num).toDouble();
    final totalAmount = (_order!['total_amount'] as num).toDouble();
    final couponCode = _order!['coupon_code'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.priceBreakdown,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildPriceRow(l10n.subtotal, subtotal),
            _buildPriceRow(l10n.vat, vatAmount),
            if (deliveryFee > 0) _buildPriceRow(l10n.deliveryFeeLabel, deliveryFee),
            if (discountAmount > 0)
              _buildPriceRow(
                '${l10n.discount}${couponCode != null ? ' ($couponCode)' : ''}',
                -discountAmount,
                color: Colors.green,
              ),
            const Divider(height: 24, thickness: 2),
            _buildPriceRow(
              l10n.total,
              totalAmount,
              isBold: true,
              fontSize: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    Color? color,
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} SAR',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final l10n = AppLocalizations.of(context)!;
    final paymentMethod = _order!['payment_method'] as String?;
    final paymentStatus = _order!['payment_status'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.paymentMethodLabel,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      paymentMethod == 'cash' ? l10n.cashOnDelivery : l10n.cardPayment,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(paymentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getPaymentStatusColor(paymentStatus).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    paymentStatus.toUpperCase(),
                    style: TextStyle(
                      color: _getPaymentStatusColor(paymentStatus),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isCancelling ? null : _showCancelDialog,
        icon: const Icon(Icons.cancel_outlined),
        label: _isCancelling
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.cancelOrder),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildReviewButton() {
  final l10n = AppLocalizations.of(context)!;
  return FutureBuilder<bool>(
    future: _reviewsService.hasReviewedOrder(
      widget.orderId,
      _supabase.auth.currentUser!.id,
    ),
    builder: (context, snapshot) {
      // If already reviewed, show message
      if (snapshot.hasData && snapshot.data == true) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              Text(
                l10n.youReviewedThisOrder,
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      // If not reviewed, show button
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubmitReviewScreen(
                  orderId: widget.orderId,
                  order: _order!,
                ),
              ),
            );
            // If review was submitted, refresh to hide button
            if (result == true && mounted) {
              setState(() {}); // Trigger rebuild
            }
          },
          icon: const Icon(Icons.rate_review),
          label: Text(l10n.writeAReview),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryNavy,
            foregroundColor: Colors.white,
          ),
        ),
      );
    },
  );
}

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.teal;
      case 'dispatched':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showCancelDialog() {
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
              await _cancelOrder();
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

  Future<void> _cancelOrder() async {
    setState(() => _isCancelling = true);

    try {
      await _ordersService.cancelOrder(widget.orderId);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.cancelOrder} ${l10n.success.toLowerCase()}'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to orders list and pass true to indicate refresh needed
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
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