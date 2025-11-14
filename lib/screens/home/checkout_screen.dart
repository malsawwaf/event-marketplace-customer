import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/cart_service.dart';
import '../../services/address_service.dart';
import '../../services/paymob_intention_service.dart';
import '../../services/paymob_sdk_service.dart';
import '../../config/app_theme.dart';
import 'address_selection_screen.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String cartId;
  final String providerId;

  const CheckoutScreen({
    Key? key,
    required this.cartId,
    required this.providerId,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _supabase = Supabase.instance.client;
  final _couponController = TextEditingController();

  Map<String, dynamic>? _cartData;
  Map<String, dynamic>? _selectedAddress;
  Map<String, Map<String, DateTime?>> _itemDates = {};
  Map<String, Map<String, TimeOfDay?>> _itemTimes = {};
  Set<String> _expandedItems = {};
  
  bool _isLoading = true;
  bool _isPlacingOrder = false;
  String _paymentMethod = 'cash';
  String? _appliedCouponCode;
  double _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadCheckoutData();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadCheckoutData() async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    setState(() => _isLoading = true);

    try {
      final cartService = CartService();
      final carts = await cartService.getCustomerCarts(customerId);
      final cart = carts.firstWhere(
        (c) => c['id'] == widget.cartId,
        orElse: () => <String, dynamic>{},
      );

      final addressService = AddressService();
      final address = await addressService.getDefaultAddress(customerId);

      if (mounted) {
        setState(() {
          _cartData = cart;
          _selectedAddress = address;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading checkout: $e')),
        );
      }
    }
  }

  bool _validateDates() {
    final items = _cartData!['items'] as List<dynamic>;

    for (final cartItem in items) {
      final cartItemId = cartItem['id'] as String;
      final item = cartItem['items'] as Map<String, dynamic>;
      final pricingType = item['pricing_type'] as String;

      final dates = _itemDates[cartItemId];
      final times = _itemTimes[cartItemId];

      if (pricingType == 'per_day') {
        if (dates == null || dates['startDate'] == null || dates['endDate'] == null ||
            times == null || times['startTime'] == null || times['endTime'] == null) {
          return false;
        }
      } else {
        if (dates == null || dates['eventDate'] == null ||
            times == null || times['eventTime'] == null) {
          return false;
        }
      }
    }

    return true;
  }

  /// Calculate rental days based on 24-hour periods with 4-hour grace period
  int _calculateRentalDays(DateTime startDateTime, DateTime endDateTime) {
    final totalHours = endDateTime.difference(startDateTime).inHours;
    final totalMinutes = endDateTime.difference(startDateTime).inMinutes;

    // Calculate full 24-hour periods
    final fullDays = totalHours ~/ 24;

    // Calculate remaining hours and minutes
    final remainingMinutes = totalMinutes % (24 * 60);
    final remainingHours = remainingMinutes / 60;

    // If remaining time is more than 4 hours, charge an extra day
    if (remainingHours > 4) {
      return fullDays + 1;
    }

    // Minimum 1 day rental
    return fullDays > 0 ? fullDays : 1;
  }

  double _calculateItemTotal(Map<String, dynamic> cartItem) {
    final item = cartItem['items'] as Map<String, dynamic>;
    final cartItemId = cartItem['id'] as String;
    final quantity = cartItem['quantity'] as int;
    final addons = cartItem['addons'] as List<dynamic>?;
    final price = (item['price'] as num).toDouble();
    final pricingType = item['pricing_type'] as String;

    int days = 1;
    if (pricingType == 'per_day') {
      final dates = _itemDates[cartItemId];
      final times = _itemTimes[cartItemId];

      if (dates?['startDate'] != null && dates?['endDate'] != null &&
          times?['startTime'] != null && times?['endTime'] != null) {

        final startDate = dates!['startDate']!;
        final endDate = dates['endDate']!;
        final startTime = times!['startTime']!;
        final endTime = times['endTime']!;

        // Combine date and time into DateTime objects
        final startDateTime = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          startTime.hour,
          startTime.minute,
        );

        final endDateTime = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          endTime.hour,
          endTime.minute,
        );

        days = _calculateRentalDays(startDateTime, endDateTime);
      }
    }

    double itemTotal = pricingType == 'per_day'
        ? price * days * quantity
        : price * quantity;

    if (addons != null && addons.isNotEmpty) {
      for (final addon in addons) {
        final addonPrice = (addon['additional_price'] as num).toDouble();
        itemTotal += pricingType == 'per_day'
            ? addonPrice * days * quantity
            : addonPrice * quantity;
      }
    }

    return itemTotal;
  }

  Map<String, double> _calculateTotals() {
    final items = _cartData!['items'] as List<dynamic>;
    
    double subtotal = 0;
    for (final cartItem in items) {
      subtotal += _calculateItemTotal(cartItem);
    }

    final vatAmount = subtotal * 0.15;
    final deliveryFee = 0.0;
    final total = subtotal + vatAmount + deliveryFee - _discountAmount;

    return {
      'subtotal': subtotal,
      'vat': vatAmount,
      'delivery_fee': deliveryFee,
      'discount': _discountAmount,
      'total': total,
    };
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressSelectionScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedAddress = result);
    }
  }

  Future<void> _applyCoupon() async {
    final couponCode = _couponController.text.trim().toUpperCase();
    if (couponCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coupon code')),
      );
      return;
    }

    try {
      final response = await _supabase
          .from('coupons')
          .select()
          .eq('code', couponCode)
          .eq('is_active', true)
          .or('provider_id.eq.${widget.providerId},provider_id.is.null')
          .maybeSingle();

      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid or expired coupon')),
          );
        }
        return;
      }

      final validFrom = DateTime.parse(response['valid_from']);
      final validUntil = DateTime.parse(response['valid_until']);
      final now = DateTime.now();

      if (now.isBefore(validFrom) || now.isAfter(validUntil)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coupon has expired')),
          );
        }
        return;
      }

      final totals = _calculateTotals();
      final subtotal = totals['subtotal']!;
      final minOrderAmount = (response['min_order_amount'] as num?)?.toDouble();

      if (minOrderAmount != null && subtotal < minOrderAmount) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Minimum order amount for this coupon is $minOrderAmount SAR',
              ),
            ),
          );
        }
        return;
      }

      final discountType = response['discount_type'] as String;
      final discountValue = (response['discount_value'] as num).toDouble();
      final maxDiscount = (response['max_discount_amount'] as num?)?.toDouble();

      double discount = 0;
      if (discountType == 'percentage') {
        discount = subtotal * (discountValue / 100);
        if (maxDiscount != null && discount > maxDiscount) {
          discount = maxDiscount;
        }
      } else {
        discount = discountValue;
      }

      if (mounted) {
        setState(() {
          _appliedCouponCode = couponCode;
          _discountAmount = discount;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon applied! You saved ${discount.toStringAsFixed(2)} SAR'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying coupon: $e')),
        );
      }
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _discountAmount = 0;
      _couponController.clear();
    });
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    if (!_validateDates()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select event dates for all items')),
      );
      return;
    }

    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    setState(() => _isPlacingOrder = true);

    // Handle online card payment
    if (_paymentMethod == 'card') {
      await _processOnlinePayment(customerId);
      return;
    }

    // Continue with cash on delivery
    await _createOrder(customerId, paymentTransactionId: null);

    try {
      final items = _cartData!['items'] as List<dynamic>;
      final provider = _cartData!['providers'] as Map<String, dynamic>;
      
      final totals = _calculateTotals();

      final addressService = AddressService();
      final formattedAddress = addressService.formatAddress(_selectedAddress!);
      
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      final timerMinutes = provider['order_acceptance_timer_minutes'] as int? ?? 30;
      final acceptanceDeadline = DateTime.now().add(Duration(minutes: timerMinutes));

      final order = await _supabase.from('orders').insert({
        'customer_id': customerId,
        'provider_id': widget.providerId,
        'order_number': orderNumber,
        'delivery_address': formattedAddress,
        'delivery_location': _selectedAddress!['location'],
        'subtotal': totals['subtotal'],
        'vat_amount': totals['vat'],
        'delivery_fee': totals['delivery_fee'],
        'discount_amount': _discountAmount,
        'total_amount': totals['total'],
        'status': 'pending',
        'payment_status': 'pending',
        'payment_method': _paymentMethod,
        'coupon_code': _appliedCouponCode,
        'acceptance_deadline': acceptanceDeadline.toIso8601String(),
        'event_date': DateTime.now().toIso8601String(),
      }).select().single();

      final orderId = order['id'] as String;

      for (final cartItem in items) {
        final item = cartItem['items'] as Map<String, dynamic>;
        final cartItemId = cartItem['id'] as String;
        final quantity = cartItem['quantity'] as int;
        final addons = cartItem['addons'] as List<dynamic>?;
        
        final price = (item['price'] as num).toDouble();
        final pricingType = item['pricing_type'] as String;

        final dates = _itemDates[cartItemId];
        final times = _itemTimes[cartItemId];

        int days = 1;
        DateTime? eventDateTime;
        DateTime? eventStartDateTime;
        DateTime? eventEndDateTime;

        if (pricingType == 'per_day') {
          // Combine dates and times for per_day items
          if (dates?['startDate'] != null && times?['startTime'] != null) {
            final startDate = dates!['startDate']!;
            final startTime = times!['startTime']!;
            eventStartDateTime = DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
              startTime.hour,
              startTime.minute,
            );
          }

          if (dates?['endDate'] != null && times?['endTime'] != null) {
            final endDate = dates!['endDate']!;
            final endTime = times!['endTime']!;
            eventEndDateTime = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
              endTime.hour,
              endTime.minute,
            );
          }

          if (eventStartDateTime != null && eventEndDateTime != null) {
            days = _calculateRentalDays(eventStartDateTime, eventEndDateTime);
          }
        } else {
          // Combine date and time for per_event and purchasable items
          if (dates?['eventDate'] != null && times?['eventTime'] != null) {
            final eventDate = dates!['eventDate']!;
            final eventTime = times!['eventTime']!;
            eventDateTime = DateTime(
              eventDate.year,
              eventDate.month,
              eventDate.day,
              eventTime.hour,
              eventTime.minute,
            );
          }
        }

        final unitPrice = price;
        final subtotal = pricingType == 'per_day'
            ? price * days * quantity
            : price * quantity;

        final orderItem = await _supabase.from('order_items').insert({
          'order_id': orderId,
          'item_id': item['id'],
          'quantity': quantity,
          'unit_price': unitPrice,
          'subtotal': subtotal,
          'event_date': eventDateTime?.toIso8601String(),
          'event_start_date': eventStartDateTime?.toIso8601String(),
          'event_end_date': eventEndDateTime?.toIso8601String(),
        }).select().single();

        final orderItemId = orderItem['id'] as String;

        if (addons != null && addons.isNotEmpty) {
          for (final addon in addons) {
            await _supabase.from('order_item_addons').insert({
              'order_item_id': orderItemId,
              'addon_id': addon['item_addon_id'],
              'addon_name': addon['addon_name'],
              'addon_price': addon['additional_price'],
            });
          }
        }

        await _supabase
            .from('stock_reservations')
            .update({
              'status': 'completed',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('cart_item_id', cartItemId);

        await _supabase.rpc('deduct_stock', params: {
          'p_item_id': item['id'],
          'p_quantity': quantity,
        });
      }

      final cartService = CartService();
      await cartService.clearCart(widget.cartId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderId: orderId,
              orderNumber: orderNumber,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    }
  }

  /// Process online payment via Paymob
  Future<void> _processOnlinePayment(String customerId) async {
    try {
      final totals = _calculateTotals();
      final customer = await _supabase
          .from('customers')
          .select()
          .eq('id', customerId)
          .single();

      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      // Step 1: Create Payment Intention with Paymob
      print('🔵 Creating payment intention...');

      // Parse customer name (ensure lastName is never blank)
      final fullName = customer['full_name']?.toString() ?? 'Customer';
      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : firstName;

      final intentionService = PaymobIntentionService();
      final intentionResult = await intentionService.createIntention(
        amount: totals['total']!,
        customerFirstName: firstName,
        customerLastName: lastName,
        customerEmail: customer['email'] ?? 'customer@example.com',
        customerPhone: customer['phone_number'] ?? '0500000000',
        orderNumber: orderNumber,
        country: 'SA',
      );

      if (intentionResult['error'] != null) {
        if (mounted) {
          setState(() => _isPlacingOrder = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to initiate payment: ${intentionResult['error']}')),
          );
        }
        return;
      }

      final clientSecret = intentionResult['client_secret'] as String;
      final intentionId = intentionResult['intention_id'] as String?;

      print('✅ Intention created: $intentionId');

      // Step 2: Launch Paymob SDK for payment
      print('🔵 Launching Paymob SDK...');
      final sdkService = PaymobSDKService();
      final paymentResult = await sdkService.processPayment(
        clientSecret: clientSecret,
        appName: 'Azimah Tech',
      );

      print('Payment result: ${paymentResult['status']}');

      // Step 3: Verify transaction status with Paymob API
      // SDK callbacks are sometimes unreliable, so we verify with the API
      print('🔍 Verifying transaction status with Paymob API...');
      Map<String, dynamic>? verification;

      if (intentionId != null) {
        verification = await intentionService.verifyTransaction(intentionId);
        print('✅ Verification result: ${verification['status']} - Success: ${verification['success']}');
      }

      // Step 4: Handle payment result (prioritize API verification over SDK callback)
      if (mounted) {
        final bool isActuallySuccessful = verification?['success'] == true ||
                                          paymentResult['success'] == true;

        if (isActuallySuccessful) {
          // Payment successful - create order
          print('✅ Payment verified successful, creating order...');
          await _createOrder(customerId, paymentTransactionId: intentionId);
        } else if (paymentResult['status'] == 'Cancelled') {
          // User explicitly cancelled - don't verify
          setState(() => _isPlacingOrder = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled')),
          );
        } else if (verification?['status'] == 'PENDING' || paymentResult['status'] == 'Pending') {
          // Payment still pending
          setState(() => _isPlacingOrder = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment is pending verification. Please check your order status.'),
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          // Payment failed or rejected
          setState(() => _isPlacingOrder = false);
          final sdkMessage = paymentResult['status'] == 'Rejected'
              ? 'Payment was declined by your bank.'
              : (paymentResult['error'] ?? 'Payment failed.');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sdkMessage),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _processOnlinePayment: $e');
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
    }
  }

  /// Create order in database
  Future<void> _createOrder(String customerId, {String? paymentTransactionId}) async {
    try {
      final items = _cartData!['items'] as List<dynamic>;
      final provider = _cartData!['providers'] as Map<String, dynamic>;

      final totals = _calculateTotals();

      final addressService = AddressService();
      final formattedAddress = addressService.formatAddress(_selectedAddress!);

      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      final timerMinutes = provider['order_acceptance_timer_minutes'] as int? ?? 30;
      final acceptanceDeadline = DateTime.now().add(Duration(minutes: timerMinutes));

      final order = await _supabase.from('orders').insert({
        'customer_id': customerId,
        'provider_id': widget.providerId,
        'order_number': orderNumber,
        'delivery_address': formattedAddress,
        'delivery_location': _selectedAddress!['location'],
        'subtotal': totals['subtotal'],
        'vat_amount': totals['vat'],
        'delivery_fee': totals['delivery_fee'],
        'discount_amount': _discountAmount,
        'total_amount': totals['total'],
        'status': 'pending',
        'payment_status': _paymentMethod == 'card' ? 'paid' : 'pending',
        'payment_method': _paymentMethod,
        'payment_transaction_id': paymentTransactionId,
        'coupon_code': _appliedCouponCode,
        'acceptance_deadline': acceptanceDeadline.toIso8601String(),
        'event_date': DateTime.now().toIso8601String(),
      }).select().single();

      final orderId = order['id'] as String;

      for (final cartItem in items) {
        final item = cartItem['items'] as Map<String, dynamic>;
        final cartItemId = cartItem['id'] as String;
        final quantity = cartItem['quantity'] as int;
        final addons = cartItem['addons'] as List<dynamic>?;

        final price = (item['price'] as num).toDouble();
        final pricingType = item['pricing_type'] as String;

        final dates = _itemDates[cartItemId];
        final times = _itemTimes[cartItemId];

        int days = 1;
        DateTime? eventDateTime;
        DateTime? eventStartDateTime;
        DateTime? eventEndDateTime;

        if (pricingType == 'per_day') {
          // Combine dates and times for per_day items
          if (dates?['startDate'] != null && times?['startTime'] != null) {
            final startDate = dates!['startDate']!;
            final startTime = times!['startTime']!;
            eventStartDateTime = DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
              startTime.hour,
              startTime.minute,
            );
          }

          if (dates?['endDate'] != null && times?['endTime'] != null) {
            final endDate = dates!['endDate']!;
            final endTime = times!['endTime']!;
            eventEndDateTime = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
              endTime.hour,
              endTime.minute,
            );
          }

          if (eventStartDateTime != null && eventEndDateTime != null) {
            days = _calculateRentalDays(eventStartDateTime, eventEndDateTime);
          }
        } else {
          // Combine date and time for per_event and purchasable items
          if (dates?['eventDate'] != null && times?['eventTime'] != null) {
            final eventDate = dates!['eventDate']!;
            final eventTime = times!['eventTime']!;
            eventDateTime = DateTime(
              eventDate.year,
              eventDate.month,
              eventDate.day,
              eventTime.hour,
              eventTime.minute,
            );
          }
        }

        final unitPrice = price;
        final subtotal = pricingType == 'per_day'
            ? price * days * quantity
            : price * quantity;

        final orderItem = await _supabase.from('order_items').insert({
          'order_id': orderId,
          'item_id': item['id'],
          'quantity': quantity,
          'unit_price': unitPrice,
          'subtotal': subtotal,
          'event_date': eventDateTime?.toIso8601String(),
          'event_start_date': eventStartDateTime?.toIso8601String(),
          'event_end_date': eventEndDateTime?.toIso8601String(),
        }).select().single();

        final orderItemId = orderItem['id'] as String;

        if (addons != null && addons.isNotEmpty) {
          for (final addon in addons) {
            await _supabase.from('order_item_addons').insert({
              'order_item_id': orderItemId,
              'addon_id': addon['item_addon_id'],
              'addon_name': addon['addon_name'],
              'addon_price': addon['additional_price'],
            });
          }
        }

        await _supabase
            .from('stock_reservations')
            .update({
              'status': 'completed',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('cart_item_id', cartItemId);

        await _supabase.rpc('deduct_stock', params: {
          'p_item_id': item['id'],
          'p_quantity': quantity,
        });
      }

      final cartService = CartService();
      await cartService.clearCart(widget.cartId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderId: orderId,
              orderNumber: orderNumber,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cartData == null || _cartData!['items'] == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Cart not found')),
      );
    }

    final provider = _cartData!['providers'] as Map<String, dynamic>;
    final items = _cartData!['items'] as List<dynamic>;
    final totals = _calculateTotals();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProviderSection(provider),
                const SizedBox(height: 16),
                _buildAddressSection(),
                const SizedBox(height: 16),
                _buildOrderItemsSection(items),
                const SizedBox(height: 16),
                _buildCouponSection(),
                const SizedBox(height: 16),
                _buildPaymentMethodSection(),
                const SizedBox(height: 16),
                _buildOrderSummary(totals),
              ],
            ),
          ),
          _buildPlaceOrderButton(totals['total']!),
        ],
      ),
    );
  }

  Widget _buildProviderSection(Map<String, dynamic> provider) {
    final companyName = provider['company_name_en'] as String;
    final photoUrl = provider['profile_photo_url'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? const Icon(Icons.business) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ordering from',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    companyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    final addressService = AddressService();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryNavy),
                const SizedBox(width: 8),
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedAddress != null) ...[
              Text(
                _selectedAddress!['label'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                addressService.formatAddress(_selectedAddress!),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Text(
                'No address selected',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _selectAddress,
                icon: Icon(_selectedAddress != null ? Icons.edit : Icons.add),
                label: Text(_selectedAddress != null ? 'Change Address' : 'Add Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection(List<dynamic> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag, color: AppTheme.primaryNavy),
                const SizedBox(width: 8),
                Text(
                  'Order Items (${items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((cartItem) => _buildExpandableItemCard(cartItem)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableItemCard(Map<String, dynamic> cartItem) {
    final item = cartItem['items'] as Map<String, dynamic>;
    final cartItemId = cartItem['id'] as String;
    final quantity = cartItem['quantity'] as int;
    final addons = cartItem['addons'] as List<dynamic>?;

    final name = item['name'] as String;
    final price = (item['price'] as num).toDouble();
    final pricingType = item['pricing_type'] as String;

    final isExpanded = _expandedItems.contains(cartItemId);
    final dates = _itemDates[cartItemId];
    final times = _itemTimes[cartItemId];
    final itemTotal = _calculateItemTotal(cartItem);

    int days = 1;
    if (pricingType == 'per_day') {
      if (dates?['startDate'] != null && dates?['endDate'] != null &&
          times?['startTime'] != null && times?['endTime'] != null) {
        final startDate = dates!['startDate']!;
        final endDate = dates['endDate']!;
        final startTime = times!['startTime']!;
        final endTime = times['endTime']!;

        final startDateTime = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          startTime.hour,
          startTime.minute,
        );

        final endDateTime = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          endTime.hour,
          endTime.minute,
        );

        days = _calculateRentalDays(startDateTime, endDateTime);
      }
    }

    String pricingLabel = pricingType == 'per_day' 
        ? 'per day' 
        : pricingType == 'per_event' 
            ? 'per event' 
            : 'purchase';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(cartItemId);
                } else {
                  _expandedItems.add(cartItemId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${itemTotal.toStringAsFixed(2)} SAR',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Base Price', '$price SAR $pricingLabel'),
                  _buildDetailRow('Quantity', '×$quantity'),
                  if (pricingType == 'per_day' && days > 1)
                    _buildDetailRow('Days', '×$days days'),
                  
                  if (addons != null && addons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Add-ons:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    ...addons.map((addon) {
                      final addonName = addon['addon_name'] as String;
                      final addonPrice = (addon['additional_price'] as num).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: _buildDetailRow(
                          '+ $addonName',
                          '$addonPrice SAR',
                        ),
                      );
                    }),
                  ],
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Event Date:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (pricingType == 'per_day') ...[
                    // Start Date & Time
                    const Text(
                      'Start Date & Time:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dates?['startDate'] ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _itemDates[cartItemId] = {
                                    ...?dates,
                                    'startDate': picked,
                                  };
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text(
                              dates?['startDate'] != null
                                  ? '${dates!['startDate']!.day}/${dates['startDate']!.month}/${dates['startDate']!.year}'
                                  : 'Date',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: times?['startTime'] ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _itemTimes[cartItemId] = {
                                    ...?times,
                                    'startTime': picked,
                                  };
                                });
                              }
                            },
                            icon: const Icon(Icons.access_time, size: 14),
                            label: Text(
                              times?['startTime'] != null
                                  ? times!['startTime']!.format(context)
                                  : 'Time',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // End Date & Time
                    const Text(
                      'End Date & Time:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final startDate = dates?['startDate'];
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dates?['endDate'] ??
                                    (startDate?.add(const Duration(days: 1)) ?? DateTime.now()),
                                firstDate: startDate ?? DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _itemDates[cartItemId] = {
                                    ...?dates,
                                    'endDate': picked,
                                  };
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text(
                              dates?['endDate'] != null
                                  ? '${dates!['endDate']!.day}/${dates['endDate']!.month}/${dates['endDate']!.year}'
                                  : 'Date',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: times?['endTime'] ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _itemTimes[cartItemId] = {
                                    ...?times,
                                    'endTime': picked,
                                  };
                                });
                              }
                            },
                            icon: const Icon(Icons.access_time, size: 14),
                            label: Text(
                              times?['endTime'] != null
                                  ? times!['endTime']!.format(context)
                                  : 'Time',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Show calculated days
                    if (dates?['startDate'] != null && dates?['endDate'] != null &&
                        times?['startTime'] != null && times?['endTime'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Rental Period: $days day${days > 1 ? 's' : ''} (includes 4-hour grace period)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Event/Delivery Date & Time
                    Text(
                      pricingType == 'purchasable' ? 'Delivery Date & Time:' : 'Event Date & Time:',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dates?['eventDate'] ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _itemDates[cartItemId] = {
                                    'eventDate': picked,
                                  };
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text(
                              dates?['eventDate'] != null
                                  ? '${dates!['eventDate']!.day}/${dates['eventDate']!.month}/${dates['eventDate']!.year}'
                                  : 'Date',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: times?['eventTime'] ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _itemTimes[cartItemId] = {
                                    'eventTime': picked,
                                  };
                                });
                              }
                            },
                            icon: const Icon(Icons.access_time, size: 14),
                            label: Text(
                              times?['eventTime'] != null
                                  ? times!['eventTime']!.format(context)
                                  : 'Time',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.discount, color: AppTheme.primaryNavy),
                const SizedBox(width: 8),
                const Text(
                  'Coupon Code',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_appliedCouponCode != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _appliedCouponCode!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Saved ${_discountAmount.toStringAsFixed(2)} SAR',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _removeCoupon,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: const InputDecoration(
                        hintText: 'Enter coupon code',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyCoupon,
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppTheme.primaryNavy),
                const SizedBox(width: 8),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when order is delivered'),
              value: 'cash',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              title: const Text('Card Payment'),
              subtitle: const Text('Pay securely online via Paymob'),
              value: 'card',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value!),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Map<String, double> totals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Subtotal', totals['subtotal']!),
            _buildSummaryRow('VAT (15%)', totals['vat']!),
            if (totals['delivery_fee']! > 0)
              _buildSummaryRow('Delivery Fee', totals['delivery_fee']!),
            if (totals['discount']! > 0)
              _buildSummaryRow('Discount', -totals['discount']!, color: Colors.green),
            const Divider(height: 24, thickness: 2),
            _buildSummaryRow(
              'Total',
              totals['total']!,
              isBold: true,
              fontSize: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
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

  Widget _buildPlaceOrderButton(double total) {
    final allDatesValid = _validateDates();
    final canPlaceOrder = !_isPlacingOrder && _selectedAddress != null && allDatesValid;

    String buttonText = 'Place Order - ${total.toStringAsFixed(2)} SAR';
    if (_selectedAddress == null) {
      buttonText = 'Select Address First';
    } else if (!allDatesValid) {
      buttonText = 'Select Event Dates';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: canPlaceOrder ? _placeOrder : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}