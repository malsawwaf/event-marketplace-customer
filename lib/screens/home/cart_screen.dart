import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../services/cart_service.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _carts = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCarts();
    // Refresh every 5 seconds to update expiry timers and catch new items quickly
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadCarts();
    });
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
        final l10n = AppLocalizations.of(context);
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFromCart),
        content: Text(l10n.confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final cartService = CartService();

    try {
      await cartService.removeItemFromCart(cartItemId);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.removeFromCart)),
        );
        _loadCarts();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(String cartItemId, int currentQuantity, bool increase) async {
    final cartService = CartService();
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    final newQuantity = increase ? currentQuantity + 1 : currentQuantity - 1;

    // Optimistic update - update UI immediately
    setState(() {
      for (var cart in _carts) {
        final items = cart['items'] as List<dynamic>;
        for (var item in items) {
          if (item['id'] == cartItemId) {
            item['quantity'] = newQuantity;
            break;
          }
        }
      }
    });

    try {
      await cartService.updateCartItemQuantity(
        customerId: customerId,
        cartItemId: cartItemId,
        newQuantity: newQuantity,
      );
    } catch (e) {
      // Revert on error
      if (mounted) {
        _loadCarts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  String _getTimeRemaining(DateTime expiresAt) {
    final l10n = AppLocalizations.of(context);
    // Ensure both times are in UTC for consistent comparison
    final now = DateTime.now().toUtc();
    final expiresAtUtc = expiresAt.toUtc();
    final difference = expiresAtUtc.difference(now);

    if (difference.isNegative) {
      return l10n.expired;
    }

    final totalMinutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;

    // If more than 60 minutes, show hours
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return '${hours}h ${minutes}m';
    }

    return '${totalMinutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cart)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_carts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cart)),
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
                l10n.cartEmpty,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.continueShopping,
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
        title: Text(l10n.cart),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCarts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCarts,
        color: AppTheme.primaryNavy,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _carts.length,
          itemBuilder: (context, index) => _buildProviderCart(_carts[index]),
        ),
      ),
    );
  }

  Widget _buildProviderCart(Map<String, dynamic> cart) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final provider = cart['providers'] as Map<String, dynamic>;
    final items = cart['items'] as List<dynamic>;
    final companyNameEn = provider['company_name_en'] as String;
    final companyNameAr = provider['company_name_ar'] as String?;
    final companyName = isArabic && companyNameAr != null ? companyNameAr : companyNameEn;
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
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                _buildTotalRow(l10n.subtotal, totals['subtotal']!),
                _buildTotalRow(l10n.taxLabel, totals['vat']!),
                if (totals['delivery_fee']! > 0)
                  _buildTotalRow(l10n.deliveryFeeLabel, totals['delivery_fee']!),
                if (totals['discount']! > 0)
                  _buildTotalRow(l10n.discount, -totals['discount']!, color: Colors.green),
                const Divider(thickness: 2),
                _buildTotalRow(
                  l10n.total,
                  totals['total']!,
                  isBold: true,
                  fontSize: 18,
                ),
                // Check if any items are per_day
                if (items.any((item) {
                  final itemData = item['items'] as Map<String, dynamic>;
                  return itemData['pricing_type'] == 'per_day';
                })) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.rentalPeriodSetInCheckout,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                      backgroundColor: AppTheme.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n.proceedToCheckout,
                      style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final item = cartItem['items'] as Map<String, dynamic>;
    final cartItemId = cartItem['id'] as String;
    final quantity = cartItem['quantity'] as int;
    final addons = cartItem['addons'] as List<dynamic>?;
    final reservation = cartItem['reservation'] as Map<String, dynamic>?;
    final notes = cartItem['notes'] as String?;

    final nameEn = item['name'] as String;
    final nameAr = item['name_ar'] as String?;
    final name = isArabic && nameAr != null ? nameAr : nameEn;

    final price = (item['price'] as num).toDouble();
    final pricingType = item['pricing_type'] as String;
    final photoUrls = item['photo_urls'] as List<dynamic>?;
    final minQuantity = item['min_order_quantity'] as int? ?? 1;
    final maxQuantity = item['max_order_quantity'] as int?;

    final photoUrl = (photoUrls != null && photoUrls.isNotEmpty)
        ? photoUrls.first as String
        : null;

    // Calculate item total
    // For per_day items, show base price only - final price calculated at checkout with times
    double itemTotal = price * quantity;

    // Add addons to total (base price)
    if (addons != null && addons.isNotEmpty) {
      for (final addon in addons) {
        final addonPrice = (addon['additional_price'] as num).toDouble();
        itemTotal += addonPrice * quantity;
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
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$price ${l10n.sar} ${pricingType == 'per_day' ? 'per day' : pricingType == 'per_event' ? 'per event' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (pricingType == 'per_day') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 12, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              l10n.rentalPeriodSetInCheckout,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (addons != null && addons.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.addons}: ${addons.map((a) => a['addon_name']).join(', ')}',
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
                '${itemTotal.toStringAsFixed(2)} ${l10n.sar}',
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
                    '${l10n.reserved}: ${_getTimeRemaining(expiresAt)}',
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
            '${amount.toStringAsFixed(2)} ﷼',
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