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

  // Profile Screen
  String get areYouSureLogout;
  String get manageAddresses;
  String get addOrEditDeliveryAddresses;
  String get settings;
  String get appPreferencesAndSecurity;
  String get helpAndSupport;
  String get getHelpOrContactUs;
  String get helpAndSupportComingSoon;
  String get about;
  String get appVersionAndInformation;
  String get aboutAzimahTech;
  String get version;
  String get azimahTechEventMarketplace;
  String get browseAndBookEventServices;
  String get copyrightAzimahTech;

  // Settings Screen
  String get account;
  String get changePassword;
  String get notifications;
  String get pushNotifications;
  String get receiveOrderUpdates;
  String get emailNotifications;
  String get receiveUpdatesViaEmail;
  String get smsNotifications;
  String get receiveUpdatesViaSMS;
  String get aboutApp;
  String get privacyPolicy;
  String get privacyPolicyComingSoon;
  String get termsOfService;
  String get termsOfServiceComingSoon;
  String get currentPassword;
  String get pleaseEnterCurrentPassword;
  String get newPassword;
  String get pleaseEnterNewPassword;
  String get passwordMustBeAtLeast6Characters;
  String get confirmNewPassword;
  String get passwordsDoNotMatch;
  String get change;
  String get passwordChangedSuccessfully;
  String get userNotFound;

  // Edit Profile Screen
  String get errorLoadingProfile;
  String get selectPhotoSource;
  String get errorPickingImage;
  String get errorUploadingImage;
  String get userNotAuthenticated;
  String get profileUpdatedSuccessfully;
  String get errorUpdatingProfile;
  String get tapToChangePhoto;
  String get phoneNumber;
  String get pleaseEnterYourFirstName;
  String get pleaseEnterYourLastName;
  String get pleaseEnterYourPhoneNumber;
  String get pleaseEnterValidPhoneNumber;
  String get saveChanges;

  // Addresses Screen
  String get myAddresses;
  String get errorLoadingAddresses;
  String get deleteAddress;
  String get areYouSureDeleteAddress;
  String get addressDeletedSuccessfully;
  String get errorDeletingAddress;
  String get defaultAddressUpdated;
  String get errorSettingDefaultAddress;
  String get addAddress;
  String get noAddressesSaved;
  String get addAnAddressToGetStarted;
  String get addressLabel;
  String get defaultLabel;
  String get setAsDefault;

  // Auth Screen Additions
  String get signInToContinue;
  String get enterYourEmail;
  String get pleaseEnterYourEmail;
  String get pleaseEnterValidEmail;
  String get enterYourPassword;
  String get pleaseEnterYourPassword;
  String get signIn;
  String get or;
  String get loginFailed;
  String get signUpToGetStarted;
  String get createPassword;
  String get pleaseMeetAllPasswordRequirements;
  String get pleaseAgreeToTermsAndPrivacy;
  String get registrationFailed;
  String get atLeast8Characters;
  String get containsNumber;
  String get containsSpecialCharacter;
  String get reEnterYourPassword;
  String get iAgreeToThe;
  String get and;
  String get alreadyHaveAccount;
  String get enterYourFirstName;
  String get enterYourLastName;
  String get phoneHint;
  String get completeYourProfile;
  String get almostThere;
  String get letsGetStarted;
  String get profileCompletedSuccessfully;
  String get errorCompletingProfile;
  String get resetYourPassword;
  String get enterEmailToResetPassword;
  String get sendResetLink;
  String get checkYourEmail;
  String get resetLinkSentTo;
  String get didNotReceiveEmail;
  String get resendLink;
  String get backToSignIn;
  String get errorSendingResetLink;
  String get resetLinkSentSuccessfully;
  String get welcomeToAzimahTech;
  String get yourEventMarketplace;
  String get selectAddress;
  String get selectedAddress;
  String get pleaseSelectAddress;
  String get noProviders;
  String get rating;
  String get viewMenu;
  String get menu;
  String get information;
  String get openingHours;
  String get location;
  String get contact;
  String get minimumOrder;
  String get deliveryFee;
  String get estimatedDelivery;
  String get addons;
  String get select;
  String get updateCart;
  String get emptyCart;
  String get yourCartIsEmpty;
  String get startShopping;
  String get orderSummary;
  String get deliveryFeeLabel;
  String get taxLabel;
  String get discount;
  String get proceedToCheckout;
  String get selectDeliveryAddress;
  String get selectEventDate;
  String get eventDateAndTime;
  String get specialInstructions;
  String get paymentMethod;
  String get cashOnDelivery;
  String get creditCard;
  String get applyCoupon;
  String get couponCode;
  String get apply;
  String get placeOrder;
  String get processing;
  String get orderPlacedSuccessfully;
  String get thankYouForYourOrder;
  String get weArePreparingYourOrder;
  String get viewOrderDetails;
  String get backToHome;
  String get activeOrders;
  String get pastOrders;
  String get reorder;
  String get cancelOrder;
  String get trackOrder;
  String get orderItems;
  String get deliveryInformation;
  String get paymentInformation;
  String get orderTimeline;
  String get placed;
  String get accepted;
  String get inPreparation;
  String get outForDelivery;
  String get completed;
  String get writeReview;
  String get rateYourExperience;
  String get howWasYourOrder;
  String get rateProvider;
  String get rateItems;
  String get yourReview;
  String get writeYourReview;
  String get submitReview;
  String get thankYouForReview;
  String get searchForItems;
  String get recentSearches;
  String get popularSearches;
  String get noResults;
  String get tryDifferentKeywords;
  String get filter;
  String get sortBy;
  String get priceRange;
  String get category;
  String get applyFilters;
  String get clearAll;
  String get noCategories;
  String get viewAll;
  String get featured;
  String get newArrivals;
  String get bestSelling;
  String get onSale;
  String get addNew;
  String get  editAddress;
  String get addressNickname;
  String get street;
  String get city;
  String get state;
  String get zipCode;
  String get country;
  String get makeDefault;
  String get saveAddress;
  String get pleaseEnterAddressNickname;
  String get pleaseEnterStreet;
  String get pleaseEnterCity;
  String get addressSavedSuccessfully;
  String get errorSavingAddress;
  String get loadingPayment;
  String get paymentCompleted;
  String get paymentFailed;
  String get paymentCancelled;
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
