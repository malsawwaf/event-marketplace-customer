import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ar.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  // Common
  String get appName;
  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get add;
  String get search;
  String get loading;
  String get error;
  String get success;
  String get confirm;
  String get yes;
  String get no;
  String get required;
  String get optional;
  String get refresh;
  String get back;
  String get next;
  String get skip;
  String get done;
  String get close;

  // Navigation
  String get home;
  String get categories;
  String get favorites;
  String get orders;
  String get profile;
  String get cart;

  // Authentication
  String get login;
  String get register;
  String get logout;
  String get email;
  String get password;
  String get confirmPassword;
  String get forgotPassword;
  String get resetPassword;
  String get emailRequired;
  String get passwordRequired;
  String get loginSuccess;
  String get registerSuccess;
  String get welcomeBack;
  String get createAccount;

  // Profile
  String get myProfile;
  String get editProfile;
  String get firstName;
  String get lastName;
  String get phone;
  String get address;
  String get updateProfile;
  String get profileUpdated;
  String get language;
  String get english;
  String get arabic;
  String get chooseFromGallery;
  String get takePhoto;
  String get profilePhotoUpdated;
  String get errorUpdatingPhoto;
  String get confirmLogout;

  // Home
  String get welcome;
  String get searchPlaceholder;
  String get popularProviders;
  String get nearbyProviders;
  String get allCategories;
  String get seeAll;

  // Providers
  String get providers;
  String get viewProvider;
  String get providerDetails;
  String get ratings;
  String get reviews;

  // Items/Products
  String get items;
  String get noItems;
  String get addToCart;
  String get itemDetails;
  String get price;
  String get quantity;
  String get inStock;
  String get outOfStock;
  String get selectOptions;

  // Cart
  String get myCart;
  String get cartEmpty;
  String get continueShopping;
  String get checkout;
  String get subtotal;
  String get total;
  String get removeFromCart;

  // Orders
  String get myOrders;
  String get noOrders;
  String get orderDetails;
  String get orderNumber;
  String get orderDate;
  String get deliveryAddress;
  String get eventDate;
  String get totalAmount;
  String get orderStatus;
  String get pending;
  String get confirmed;
  String get preparing;
  String get ready;
  String get dispatched;
  String get delivered;
  String get cancelled;

  // Favorites
  String get myFavorites;
  String get noFavorites;
  String get addToFavorites;
  String get removeFromFavorites;

  // Messages
  String get errorLoadingData;
  String get errorSavingData;
  String get somethingWentWrong;
  String get tryAgain;
  String get noInternetConnection;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'ar':
        return AppLocalizationsAr();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
