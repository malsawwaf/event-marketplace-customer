import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  Map<String, dynamic>? _customerProfile;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  Map<String, dynamic>? get customerProfile => _customerProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get hasProfile => _customerProfile != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((AuthState state) {
      _user = state.session?.user;
      if (_user != null) {
        _loadCustomerProfile();
      } else {
        _customerProfile = null;
      }
      notifyListeners();
    });

    if (_user != null) {
      _loadCustomerProfile();
    }
  }

  Future<void> _loadCustomerProfile() async {
    try {
      _customerProfile = await _authService.getCustomerProfile();
      notifyListeners();
    } catch (e) {
      print('Error loading customer profile: $e');
    }
  }
  
  //Load Customer Profile
    Future<void> refreshProfile() async {
    if (_user != null) {
      await _loadCustomerProfile();
      notifyListeners();
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Step 1: Authenticate with Supabase
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _user = response.user;

      // Step 2: Verify this user is NOT a provider
      final userId = response.user?.id;
      if (userId != null) {
        final providerCheck = await Supabase.instance.client
            .from('providers')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        // Step 3: If provider record exists, reject the login
        if (providerCheck != null) {
          // This is a provider account, not a customer
          await _authService.signOut();
          _user = null;
          _error = 'Access denied. This account is registered as a provider. Please use the Provider App.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Step 4: Customer verified (not a provider), load profile
      await _loadCustomerProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _user = null;
      _customerProfile = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create customer profile
  Future<bool> createProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? profileImageUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.createCustomerProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );

      await _loadCustomerProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update customer profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.updateCustomerProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );

      await _loadCustomerProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if user has completed profile
  Future<bool> checkProfileCompletion() async {
    return await _authService.hasCustomerProfile();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid email or password';
        case 'Email not confirmed':
          return 'Please verify your email address';
        case 'User already registered':
          return 'An account with this email already exists';
        default:
          return error.message;
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
  
  
}
