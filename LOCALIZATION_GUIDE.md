# Localization Guide for Azimah Tech Customer App

This guide explains how to use the Arabic/English localization system in the Customer App.

## Overview

The app supports both Arabic (العربية) and English languages with full RTL (Right-to-Left) support for Arabic.

## How to Use Translations in Your Code

### 1. Import AppLocalizations

At the top of your Dart file:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

### 2. Get Translations in a Widget

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return Text(l10n.home_title); // Returns "Home" in English or "الرئيسية" in Arabic
}
```

### 3. Common Usage Examples

#### In Scaffold AppBar:
```dart
Scaffold(
  appBar: AppBar(
    title: Text(l10n.home_title),
  ),
  body: ...
)
```

#### In Buttons:
```dart
ElevatedButton(
  onPressed: () {},
  child: Text(l10n.common_save),
)
```

#### In Form Fields:
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: l10n.auth_email,
    hintText: l10n.auth_emailRequired,
  ),
)
```

#### In Dialogs:
```dart
AlertDialog(
  title: Text(l10n.common_confirm),
  content: Text('Are you sure?'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(l10n.common_cancel),
    ),
    TextButton(
      onPressed: () {},
      child: Text(l10n.common_ok),
    ),
  ],
)
```

## Available Translation Keys

### Common
- `common_ok`, `common_cancel`, `common_save`, `common_delete`, `common_edit`
- `common_add`, `common_confirm`, `common_search`, `common_filter`
- `common_loading`, `common_error`, `common_success`
- `common_yes`, `common_no`, `common_back`, `common_next`
- `common_viewAll`, `common_seeMore`, `common_retry`

### Authentication
- `auth_login`, `auth_register`, `auth_logout`
- `auth_email`, `auth_password`, `auth_confirmPassword`
- `auth_forgotPassword`, `auth_resetPassword`
- `auth_emailRequired`, `auth_passwordRequired`
- `auth_loginSuccess`, `auth_registerSuccess`

### Profile
- `profile_title`, `profile_firstName`, `profile_lastName`
- `profile_phone`, `profile_completeProfile`
- `profile_editProfile`, `profile_saveProfile`
- `profile_updateSuccess`

### Navigation
- `nav_home`, `nav_categories`, `nav_favorites`
- `nav_orders`, `nav_profile`

### Home
- `home_title`, `home_welcome`, `home_searchPlaceholder`
- `home_categories`, `home_popularProviders`
- `home_nearbyProviders`

### Cart & Checkout
- `cart_title`, `cart_empty`, `cart_total`
- `cart_checkout`, `cart_continueShopping`
- `checkout_title`, `checkout_placeOrder`
- `checkout_orderPlaced`

### Orders
- `orders_title`, `orders_myOrders`, `orders_orderDetails`
- `orders_status_pending`, `orders_status_confirmed`
- `orders_status_delivered`

### Settings
- `settings_title`, `settings_language`
- `settings_notifications`, `settings_about`

### Errors
- `error_networkError`, `error_serverError`
- `error_unknownError`, `error_unauthorized`

## How to Add New Translations

1. Open `lib/l10n/app_en.arb` and add your English translation:
```json
{
  "myNewKey": "My new text in English",
  "@myNewKey": {
    "description": "Description of what this text is for"
  }
}
```

2. Open `lib/l10n/app_ar.arb` and add the Arabic translation:
```json
{
  "myNewKey": "النص الجديد بالعربية"
}
```

3. Run `flutter pub get` to regenerate the localization files

4. Use it in your code:
```dart
Text(l10n.myNewKey)
```

## Language Switching

### Using the Language Switcher Widget

Add the language switcher to your settings screen:

```dart
import 'package:event_marketplace_customer/widgets/language_switcher.dart';

// In your settings screen:
LanguageSwitcher()
```

### Using the Language Selection Dialog

Show a dialog to select language:

```dart
import 'package:event_marketplace_customer/widgets/language_switcher.dart';

ElevatedButton(
  onPressed: () => LanguageSelectionDialog.show(context),
  child: Text('Change Language'),
)
```

### Programmatic Language Change

```dart
import 'package:provider/provider.dart';
import 'package:event_marketplace_customer/providers/language_provider.dart';

// Get the provider
final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

// Change to Arabic
languageProvider.setArabic();

// Change to English
languageProvider.setEnglish();

// Check current language
if (languageProvider.isArabic) {
  print('Current language is Arabic');
}
```

## RTL Support

The app automatically switches to RTL layout when Arabic is selected. You don't need to do anything special for RTL support - Flutter handles it automatically based on the selected locale.

## Best Practices

1. **Always use translations** - Never hardcode text in English or Arabic
2. **Keep keys organized** - Use prefixes like `auth_`, `profile_`, `cart_` to group related translations
3. **Provide context** - Use the `@keyName` description in English ARB file to explain what the text is for
4. **Test both languages** - Make sure your UI works well in both Arabic (RTL) and English (LTR)
5. **Consider text length** - Arabic text is often longer than English, ensure your UI can handle varying text lengths

## Example: Complete Login Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auth_login),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: l10n.auth_email,
                hintText: l10n.auth_emailRequired,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: l10n.auth_password,
                hintText: l10n.auth_passwordRequired,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: Text(l10n.auth_login),
            ),
            TextButton(
              onPressed: () {},
              child: Text(l10n.auth_forgotPassword),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Support

For questions or issues with localization, please refer to:
- Flutter Internationalization: https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization
- ARB File Format: https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification
