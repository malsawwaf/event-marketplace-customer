import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../l10n/app_localizations.dart';

/// Paymob iFrame Payment WebView Screen
/// Displays the Paymob hosted payment page and handles payment callbacks
class PaymobWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderNumber;

  const PaymobWebViewScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderNumber,
  }) : super(key: key);

  @override
  State<PaymobWebViewScreen> createState() => _PaymobWebViewScreenState();
}

class _PaymobWebViewScreenState extends State<PaymobWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            setState(() => _isLoading = false);
            _checkForCallback(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkForCallback(String url) {
    // Check if URL contains payment callback parameters
    final uri = Uri.parse(url);

    // Success indicators in URL
    if (uri.queryParameters.containsKey('success') ||
        uri.pathSegments.contains('success') ||
        url.contains('success=true')) {
      print('✅ Payment Success detected in URL');
      Navigator.pop(context, {
        'status': 'success',
        'success': true,
        'url': url,
      });
      return;
    }

    // Failure indicators in URL
    if (uri.queryParameters.containsKey('error') ||
        uri.pathSegments.contains('failure') ||
        uri.pathSegments.contains('cancel') ||
        url.contains('success=false')) {
      print('❌ Payment Failure detected in URL');
      Navigator.pop(context, {
        'status': 'failed',
        'success': false,
        'url': url,
      });
      return;
    }

    // Check for Paymob callback endpoint
    if (url.contains('/api/acceptance/post_pay') ||
        url.contains('acceptance/callback')) {
      // Payment process completed, extract result from callback
      print('🔄 Payment callback received: $url');

      // Parse the callback data (Paymob sends transaction data in the callback)
      // Success is typically indicated by the presence of "success" parameter
      final isSuccess = uri.queryParameters['success'] == 'true' ||
          uri.queryParameters['is_success'] == 'true' ||
          !uri.queryParameters.containsKey('error');

      Navigator.pop(context, {
        'status': isSuccess ? 'success' : 'failed',
        'success': isSuccess,
        'url': url,
        'params': uri.queryParameters,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.payment),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // User cancelled payment
            Navigator.pop(context, {
              'status': 'cancelled',
              'success': false,
            });
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
