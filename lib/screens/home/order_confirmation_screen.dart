import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_theme.dart';
import '../home/bottom_nav_screen.dart'; // ✅ Import to access bottomNavKey

class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
    required this.orderNumber,
  }) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            providers!inner(
              company_name_en,
              company_name_ar,
              profile_photo_url,
              mobile,
              order_acceptance_timer_minutes
            )
          ''')
          .eq('id', widget.orderId)
          .single();

      if (mounted) {
        setState(() {
          _orderData = response;
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

  void _goToHome() {
    print('=== GO TO HOME BUTTON CLICKED ===');
    print('bottomNavKey.currentState: ${bottomNavKey.currentState}');
    
    // Pop back to BottomNavScreen
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // Switch to Home tab (index 0)
    Future.delayed(const Duration(milliseconds: 200), () {
      print('=== Attempting to switch to HOME tab ===');
      bottomNavKey.currentState?.switchToTab(0);
      print('=== SWITCHED TO HOME TAB ===');
    });
  }

  void _goToOrders() {
    print('=== GO TO ORDERS BUTTON CLICKED ===');
    print('bottomNavKey.currentState: ${bottomNavKey.currentState}');
    
    // Pop back to BottomNavScreen
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // Switch to Orders tab (index 2)
    Future.delayed(const Duration(milliseconds: 200), () {
      print('=== Attempting to switch to ORDERS tab ===');
      bottomNavKey.currentState?.switchToTab(2);
      print('=== SWITCHED TO ORDERS TAB ===');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryNavy)),
      );
    }

    if (_orderData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.orderPlacedSuccessfully),
          backgroundColor: AppTheme.primaryNavy,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(l10n.error)),
      );
    }

    final provider = _orderData!['providers'] as Map<String, dynamic>;
    final companyName = isArabic && provider['company_name_ar'] != null
        ? provider['company_name_ar'] as String
        : provider['company_name_en'] as String;
    final photoUrl = provider['profile_photo_url'] as String?;
    final timerMinutes = provider['order_acceptance_timer_minutes'] as int? ?? 30;
    final totalAmount = (_orderData!['total_amount'] as num).toDouble();
    final paymentMethod = _orderData!['payment_method'] as String;
    final acceptanceDeadline = DateTime.parse(_orderData!['acceptance_deadline']);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Success Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      l10n.orderPlacedSuccessfully,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Order Number
                    Text(
                      widget.orderNumber,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Provider Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: photoUrl != null 
                                      ? NetworkImage(photoUrl) 
                                      : null,
                                  child: photoUrl == null 
                                      ? const Icon(Icons.business, size: 30) 
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.pending,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        companyName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.timer, color: Colors.orange[700], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Provider has $timerMinutes minutes to accept',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Deadline: ${_formatDeadline(acceptanceDeadline)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.orderDetails,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              l10n.totalAmount,
                              '${totalAmount.toStringAsFixed(2)} SAR',
                              isBold: true,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              l10n.paymentMethod,
                              paymentMethod == 'cash' ? l10n.cashOnDelivery : l10n.creditCard,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              l10n.orderStatus,
                              l10n.pending,
                              valueColor: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryNavy.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: AppTheme.primaryNavy),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'What happens next?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoStep(
                            '1',
                            'The provider will review your order',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoStep(
                            '2',
                            'If accepted, you will receive confirmation',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoStep(
                            '3',
                            paymentMethod == 'cash'
                                ? 'Pay when order is delivered'
                                : 'Complete payment to proceed',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoStep(
                            '4',
                            'Track your order in the Orders tab',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _goToOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        l10n.viewOrderDetails,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _goToHome,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryNavy,
                        side: BorderSide(color: AppTheme.primaryNavy, width: 2),
                      ),
                      child: Text(
                        l10n.backToHome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryNavy,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    final minutes = difference.inMinutes;
    final hours = difference.inHours;

    if (hours > 0) {
      return '${hours}h ${minutes % 60}m remaining';
    } else {
      return '$minutes minutes remaining';
    }
  }
}