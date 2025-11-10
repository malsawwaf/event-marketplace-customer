/// Paymob Payment Gateway Configuration (KSA - Saudi Arabia)
/// Official SDK Integration with Intention API
/// Get your credentials from: https://ksa.paymob.com/portal2/en/settings
///
/// IMPORTANT: Replace these placeholder values with your actual credentials
/// from the Paymob dashboard before running the app
class PaymobConfig {
  // Public Key (from dashboard - LIVE)
  // Format: sau_pk_live_XXXXXXXXXXXXX
  static const String publicKey = 'YOUR_PAYMOB_PUBLIC_KEY_HERE';

  // Secret Key (from dashboard - LIVE - for server-side API calls)
  // Format: sau_sk_live_XXXXXXXXXXXXX
  static const String secretKey = 'YOUR_PAYMOB_SECRET_KEY_HERE';

  // Integration ID for card payments (LIVE)
  static const int cardIntegrationId = 0; // Replace with your integration ID

  // API Endpoints (KSA region)
  static const String baseUrl = 'https://ksa.paymob.com';
  static const String intentionEndpoint = '$baseUrl/v1/intention/';
  static const String checkoutUrl = '$baseUrl/unifiedcheckout/';

  // Callback URL (configured in dashboard for integration ID)
  static const String callbackUrl = '$baseUrl/api/acceptance/post_pay';

  // Currency
  static const String currency = 'SAR'; // Saudi Riyal

  // Test Mode (set to false when switching to production)
  static const bool isTestMode = false; // SWITCHED TO LIVE MODE
}
