import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Azimah Tech'**
  String get appTitle;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @common_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get common_filter;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// No description provided for @common_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get common_required;

  /// No description provided for @common_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get common_optional;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get common_skip;

  /// No description provided for @common_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get common_viewAll;

  /// No description provided for @common_seeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get common_seeMore;

  /// No description provided for @common_seeLess.
  ///
  /// In en, this message translates to:
  /// **'See Less'**
  String get common_seeLess;

  /// No description provided for @common_noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get common_noData;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @auth_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get auth_login;

  /// No description provided for @auth_register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get auth_register;

  /// No description provided for @auth_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get auth_logout;

  /// No description provided for @auth_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_email;

  /// No description provided for @auth_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_password;

  /// No description provided for @auth_confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get auth_confirmPassword;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get auth_forgotPassword;

  /// No description provided for @auth_resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get auth_resetPassword;

  /// No description provided for @auth_dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get auth_dontHaveAccount;

  /// No description provided for @auth_alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get auth_alreadyHaveAccount;

  /// No description provided for @auth_signInWith.
  ///
  /// In en, this message translates to:
  /// **'Sign in with'**
  String get auth_signInWith;

  /// No description provided for @auth_or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get auth_or;

  /// No description provided for @auth_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get auth_emailRequired;

  /// No description provided for @auth_emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get auth_emailInvalid;

  /// No description provided for @auth_passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get auth_passwordRequired;

  /// No description provided for @auth_passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get auth_passwordTooShort;

  /// No description provided for @auth_passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get auth_passwordsDontMatch;

  /// No description provided for @auth_loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged in successfully'**
  String get auth_loginSuccess;

  /// No description provided for @auth_loginError.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get auth_loginError;

  /// No description provided for @auth_registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registered successfully'**
  String get auth_registerSuccess;

  /// No description provided for @auth_registerError.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get auth_registerError;

  /// No description provided for @auth_resetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get auth_resetPasswordSuccess;

  /// No description provided for @auth_resetPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send password reset email'**
  String get auth_resetPasswordError;

  /// No description provided for @auth_accountDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied. This account is registered as a provider. Please use the Provider App.'**
  String get auth_accountDenied;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @profile_firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get profile_firstName;

  /// No description provided for @profile_lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get profile_lastName;

  /// No description provided for @profile_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profile_phone;

  /// No description provided for @profile_completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get profile_completeProfile;

  /// No description provided for @profile_editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profile_editProfile;

  /// No description provided for @profile_saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get profile_saveProfile;

  /// No description provided for @profile_firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get profile_firstNameRequired;

  /// No description provided for @profile_lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get profile_lastNameRequired;

  /// No description provided for @profile_phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get profile_phoneRequired;

  /// No description provided for @profile_phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get profile_phoneInvalid;

  /// No description provided for @profile_updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profile_updateSuccess;

  /// No description provided for @profile_updateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profile_updateError;

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_title;

  /// No description provided for @home_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get home_welcome;

  /// No description provided for @home_searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search for services...'**
  String get home_searchPlaceholder;

  /// No description provided for @home_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get home_categories;

  /// No description provided for @home_popularProviders.
  ///
  /// In en, this message translates to:
  /// **'Popular Providers'**
  String get home_popularProviders;

  /// No description provided for @home_nearbyProviders.
  ///
  /// In en, this message translates to:
  /// **'Nearby Providers'**
  String get home_nearbyProviders;

  /// No description provided for @home_featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get home_featured;

  /// No description provided for @home_newArrivals.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get home_newArrivals;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get nav_categories;

  /// No description provided for @nav_favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get nav_favorites;

  /// No description provided for @nav_orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get nav_orders;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @categories_title.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories_title;

  /// No description provided for @categories_all.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get categories_all;

  /// No description provided for @categories_noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get categories_noCategories;

  /// No description provided for @providers_title.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providers_title;

  /// No description provided for @providers_noProviders.
  ///
  /// In en, this message translates to:
  /// **'No providers available'**
  String get providers_noProviders;

  /// No description provided for @providers_rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get providers_rating;

  /// No description provided for @providers_reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get providers_reviews;

  /// No description provided for @providers_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get providers_distance;

  /// No description provided for @providers_viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get providers_viewDetails;

  /// No description provided for @cart_title.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart_title;

  /// No description provided for @cart_empty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cart_empty;

  /// No description provided for @cart_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get cart_total;

  /// No description provided for @cart_subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get cart_subtotal;

  /// No description provided for @cart_tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get cart_tax;

  /// No description provided for @cart_deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get cart_deliveryFee;

  /// No description provided for @cart_checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get cart_checkout;

  /// No description provided for @cart_continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get cart_continueShopping;

  /// No description provided for @cart_removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get cart_removeItem;

  /// No description provided for @cart_updateQuantity.
  ///
  /// In en, this message translates to:
  /// **'Update Quantity'**
  String get cart_updateQuantity;

  /// No description provided for @cart_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get cart_quantity;

  /// No description provided for @cart_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get cart_price;

  /// No description provided for @checkout_title.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout_title;

  /// No description provided for @checkout_deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get checkout_deliveryAddress;

  /// No description provided for @checkout_selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select Address'**
  String get checkout_selectAddress;

  /// No description provided for @checkout_addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get checkout_addNewAddress;

  /// No description provided for @checkout_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get checkout_paymentMethod;

  /// No description provided for @checkout_orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get checkout_orderSummary;

  /// No description provided for @checkout_placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get checkout_placeOrder;

  /// No description provided for @checkout_orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully'**
  String get checkout_orderPlaced;

  /// No description provided for @checkout_orderError.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order'**
  String get checkout_orderError;

  /// No description provided for @address_title.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get address_title;

  /// No description provided for @address_addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get address_addAddress;

  /// No description provided for @address_editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get address_editAddress;

  /// No description provided for @address_deleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get address_deleteAddress;

  /// No description provided for @address_selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select Address'**
  String get address_selectAddress;

  /// No description provided for @address_addressLine.
  ///
  /// In en, this message translates to:
  /// **'Address Line'**
  String get address_addressLine;

  /// No description provided for @address_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get address_city;

  /// No description provided for @address_state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get address_state;

  /// No description provided for @address_zipCode.
  ///
  /// In en, this message translates to:
  /// **'ZIP Code'**
  String get address_zipCode;

  /// No description provided for @address_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get address_country;

  /// No description provided for @address_setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get address_setAsDefault;

  /// No description provided for @address_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get address_default;

  /// No description provided for @address_saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Address saved successfully'**
  String get address_saveSuccess;

  /// No description provided for @address_saveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save address'**
  String get address_saveError;

  /// No description provided for @address_deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Address deleted successfully'**
  String get address_deleteSuccess;

  /// No description provided for @address_deleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete address'**
  String get address_deleteError;

  /// No description provided for @orders_title.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders_title;

  /// No description provided for @orders_myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get orders_myOrders;

  /// No description provided for @orders_orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orders_orderDetails;

  /// No description provided for @orders_orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orders_orderNumber;

  /// No description provided for @orders_orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orders_orderDate;

  /// No description provided for @orders_orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orders_orderStatus;

  /// No description provided for @orders_orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order Total'**
  String get orders_orderTotal;

  /// No description provided for @orders_noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get orders_noOrders;

  /// No description provided for @orders_trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get orders_trackOrder;

  /// No description provided for @orders_reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get orders_reorder;

  /// No description provided for @orders_cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get orders_cancelOrder;

  /// No description provided for @orders_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orders_status_pending;

  /// No description provided for @orders_status_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get orders_status_confirmed;

  /// No description provided for @orders_status_preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get orders_status_preparing;

  /// No description provided for @orders_status_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get orders_status_ready;

  /// No description provided for @orders_status_onTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get orders_status_onTheWay;

  /// No description provided for @orders_status_delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orders_status_delivered;

  /// No description provided for @orders_status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orders_status_cancelled;

  /// No description provided for @favorites_title.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites_title;

  /// No description provided for @favorites_noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favorites_noFavorites;

  /// No description provided for @favorites_addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get favorites_addToFavorites;

  /// No description provided for @favorites_removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get favorites_removeFromFavorites;

  /// No description provided for @item_title.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get item_title;

  /// No description provided for @item_addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get item_addToCart;

  /// No description provided for @item_buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get item_buyNow;

  /// No description provided for @item_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get item_description;

  /// No description provided for @item_reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get item_reviews;

  /// No description provided for @item_rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get item_rating;

  /// No description provided for @item_availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get item_availability;

  /// No description provided for @item_inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get item_inStock;

  /// No description provided for @item_outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get item_outOfStock;

  /// No description provided for @item_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get item_price;

  /// No description provided for @item_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get item_quantity;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get settings_terms;

  /// No description provided for @settings_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settings_privacy;

  /// No description provided for @settings_help.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settings_help;

  /// No description provided for @settings_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settings_version;

  /// No description provided for @language_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_english;

  /// No description provided for @language_arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get language_arabic;

  /// No description provided for @language_selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get language_selectLanguage;

  /// No description provided for @notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @notifications_noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notifications_noNotifications;

  /// No description provided for @notifications_markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notifications_markAllRead;

  /// No description provided for @error_networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get error_networkError;

  /// No description provided for @error_serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get error_serverError;

  /// No description provided for @error_unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get error_unknownError;

  /// No description provided for @error_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized. Please login again.'**
  String get error_unauthorized;

  /// No description provided for @error_notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get error_notFound;

  /// No description provided for @error_validationError.
  ///
  /// In en, this message translates to:
  /// **'Validation error. Please check your input.'**
  String get error_validationError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
