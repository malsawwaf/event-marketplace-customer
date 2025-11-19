/// Paymob Payment Gateway Configuration (KSA - Saudi Arabia)
/// iFrame Integration
/// Dashboard: https://ksa.paymob.com/portal2/en/settings
class PaymobConfig {
  // API Key for authentication
  static const String apiKey = 'ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRNeU56SXNJbTVoYldVaU9pSnBibWwwYVdGc0luMC52eFhrQThIV3pSWHFBZEt2bFNnZGFZRE9yMjFUSVRhU3FpT19vUFpMRmhTcXpnZjVlcWNpSzdBdTQ2RThXa0hOdE5NeDFaMzZTcTFzQ3JMbzBJM29vdw==';

  // Integration ID for card payments
  static const int cardIntegrationId = 18484;

  // iFrame ID for hosted payment page
  static const int iframeId = 11484;

  // HMAC Secret for transaction verification
  static const String hmacSecret = 'BED38BD3BFBC6DED0AA3BEA5474A9EA1';

  // API Endpoints (KSA region)
  static const String baseUrl = 'https://ksa.paymob.com/api';
  static const String authEndpoint = '$baseUrl/auth/tokens';
  static const String orderEndpoint = '$baseUrl/ecommerce/orders';
  static const String paymentKeyEndpoint = '$baseUrl/acceptance/payment_keys';
  static const String iframeUrl = 'https://ksa.paymob.com/api/acceptance/iframes/$iframeId';

  // Currency
  static const String currency = 'SAR'; // Saudi Riyal

  // Test Mode (set to false when using live credentials)
  static const bool isTestMode = false;
}
