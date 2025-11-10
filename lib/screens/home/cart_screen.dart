import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _carts = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCarts();
    // Refresh every 30 seconds to update expiry timers
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadCarts());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCarts() async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    final cartService = CartService();

    try {
      final carts = await cartService.getCustomerCarts(customerId);
      
      if (mounted) {
        setState(() {
          _carts = carts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text('Are you sure you want to remove this item from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final cartService = CartService();

    try {
      await cartService.removeItemFromCart(cartItemId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from cart')),
        );
        _loadCarts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(String cartItemId, int currentQuantity, bool increase) async {
    final cartService = CartService();
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    final newQuantity = increase ? currentQuantity + 1 : currentQuantity - 1;

    try {
      await cartService.updateCartItemQuantity(
        customerId: customerId,
        cartItemId: cartItemId,
        newQuantity: newQuantity,
      );

      if (mounted) {
        _loadCarts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  String _getTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;

    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping Cart')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_carts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add items to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCarts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCarts,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _carts.length,
          itemBuilder: (context, index) => _buildProviderCart(_carts[index]),
        ),
      ),
    );
  }

  Widget _buildProviderCart(Map<String, dynamic> cart) {
    final provider = cart['providers'] as Map<String, dynamic>;
    final items = cart['items'] as List<dynamic>;
    final companyName = provider['company_name_en'] as String;
    final photoUrl = provider['profile_photo_url'] as String?;

    final cartService = CartService();
    final totals = cartService.calculateCartTotals(
      cartItems: items.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.business, size: 20) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    companyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          ...items.map((item) => _buildCartItem(Map<String, dynamic>.from(item))),

          // Totals Summary
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Divider(),
                _buildTotalRow('Subtotal', totals['subtotal']!),
                _buildTotalRow('VAT (15%)', totals['vat']!),
                if (totals['delivery_fee']! > 0)
                  _buildTotalRow('Delivery Fee', totals['delivery_fee']!),
                if (totals['discount']! > 0)
                  _buildTotalRow('Discount', -totals['discount']!, color: Colors.green),
                const Divider(thickness: 2),
                _buildTotalRow(
                  'Total',
                  totals['total']!,
                  isBold: true,
                  fontSize: 18,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            cartId: cart['id'] as String,
                            providerId: provider['id'] as String,
                          ),
                        ),
                      ).then((_) => _loadCarts());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> cartItem) {
    final item = cartItem['items'] as Map<String, dynamic>;
    final cartItemId = cartItem['id'] as String;
    final quantity = cartItem['quantity'] as int;
    final addons = cartItem['addons'] as List<dynamic>?;
    final reservation = cartItem['reservation'] as Map<String, dynamic>?;
    final notes = cartItem['notes'] as String?;

    final name = item['name'] as String;
    final price = (item['price'] as num).toDouble();
    final pricingType = item['pricing_type'] as String;
    final photoUrls = item['photo_urls'] as List<dynamic>?;
    final minQuantity = item['min_order_quantity'] as int? ?? 1;
    final maxQuantity = item['max_order_quantity'] as int?;

    final photoUrl = (photoUrls != null && photoUrls.isNotEmpty)
        ? photoUrls.first as String
        : null;

    // Calculate item total
    int days = 1;
    if (pricingType == 'per_day') {
      if (cartItem['event_start_date'] != null && cartItem['event_end_date'] != null) {
        final startDate = DateTime.parse(cartItem['event_start_date']);
        final endDate = DateTime.parse(cartItem['event_end_date']);
        days = endDate.difference(startDate).inDays + 1;
      }
    }

    double itemTotal = pricingType == 'per_day' 
        ? price * days * quantity 
        : price * quantity;

    // Add addons to total
    if (addons != null && addons.isNotEmpty) {
      for (final addon in addons) {
        final addonPrice = (addon['additional_price'] as num).toDouble();
        itemTotal += pricingType == 'per_day' 
            ? addonPrice * days * quantity 
            : addonPrice * quantity;
      }
    }

    // Check if expired
    final isExpired = reservation != null && reservation['status'] == 'expired';
    
    // Get expiry time
    DateTime? expiresAt;
    if (reservation != null && reservation['expires_at'] != null) {
      expiresAt = DateTime.parse(reservation['expires_at']);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        color: isExpired ? Colors.red[50] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      ),
              ),
              const SizedBox(width: 12),

              // Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$price SAR ${pricingType == 'per_day' ? '× $days days' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (addons != null && addons.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Add-ons: ${addons.map((a) => a['addon_name']).join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Note: $notes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeItem(cartItemId),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Quantity Selector and Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: quantity <= minQuantity
                          ? null
                          : () => _updateQuantity(cartItemId, quantity, false),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: (maxQuantity != null && quantity >= maxQuantity)
                          ? null
                          : () => _updateQuantity(cartItemId, quantity, true),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),

              // Item Total
              Text(
                '${itemTotal.toStringAsFixed(2)} SAR',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          // Expiry Timer
          if (expiresAt != null && !isExpired) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Reserved: ${_getTimeRemaining(expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Expired Warning
          if (isExpired) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Reservation expired. Item will be removed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(
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
}