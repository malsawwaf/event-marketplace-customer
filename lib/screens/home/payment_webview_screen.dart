import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Payment WebView Screen
/// Displays Paymob payment iframe for card payments
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderNumber;

  const PaymentWebViewScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderNumber,
  }) : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Check if we're on the success or failure callback URL
            _handleCallbackUrl(url);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = '${AppLocalizations.of(context).errorLoadingPaymentPage}: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handleCallbackUrl(String url) {
    // Paymob callback URLs typically contain these parameters
    final uri = Uri.parse(url);

    // Check if this is a callback URL (success or failure)
    if (uri.queryParameters.containsKey('success')) {
      final success = uri.queryParameters['success'] == 'true';
      final pending = uri.queryParameters['pending'] == 'true';
      final transactionId = uri.queryParameters['id'] ?? uri.queryParameters['txn_response_code'];

      // Return result to previous screen
      if (success && !pending) {
        // Payment successful
        Navigator.of(context).pop({
          'success': true,
          'transaction_id': transactionId,
          'callback_data': uri.queryParameters,
        });
      } else if (pending) {
        // Payment pending
        Navigator.of(context).pop({
          'success': false,
          'pending': true,
          'transaction_id': transactionId,
          'message': 'Payment is pending confirmation',
          'callback_data': uri.queryParameters,
        });
      } else {
        // Payment failed
        Navigator.of(context).pop({
          'success': false,
          'pending': false,
          'transaction_id': transactionId,
          'message': 'Payment failed',
          'callback_data': uri.queryParameters,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Confirm before closing during payment
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.cancelPaymentTitle),
            content: Text(l10n.cancelPaymentMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.continuePayment),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        );

        if (shouldPop == true) {
          // Return cancelled status
          Navigator.of(context).pop({
            'success': false,
            'cancelled': true,
            'message': l10n.paymentCancelledByUser,
          });
        }

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${l10n.payment} - ${widget.orderNumber}'),
          backgroundColor: AppTheme.primaryNavy,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              // Trigger the WillPopScope logic
              final navigator = Navigator.of(context);
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.cancelPaymentTitle),
                  content: Text(l10n.cancelPaymentMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.continuePayment),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
              );

              if (shouldPop == true) {
                navigator.pop({
                  'success': false,
                  'cancelled': true,
                  'message': l10n.paymentCancelledByUser,
                });
              }
            },
          ),
        ),
        body: Stack(
          children: [
            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isLoading = true;
                          });
                          _controller.loadRequest(Uri.parse(widget.paymentUrl));
                        },
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              )
            else
              WebViewWidget(controller: _controller),
            if (_isLoading && _errorMessage == null)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryNavy),
                      SizedBox(height: 16),
                      Text(
                        l10n.loadingSecurePaymentPage,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
