import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;

  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;

  /// Initialize push notifications
  Future<void> initialize() async {
    try {
      // Initialize local notifications first
      await _initializeLocalNotifications();

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token and save it
        await _saveToken();

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((token) {
          _saveTokenToDatabase(token);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Load initial notification count
        await loadUnreadCount();
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Initialize flutter_local_notifications
  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification tapped: ${response.payload}');
        // Could navigate to notifications screen here
      },
    );

    _localNotificationsInitialized = true;
    debugPrint('Local notifications initialized');
  }

  /// Show a local notification for foreground messages
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_localNotificationsInitialized) {
      await _initializeLocalNotifications();
    }

    const androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'General Notifications',
      channelDescription: 'Order updates and general notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    debugPrint('Local notification shown: $title');
  }

  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Upsert the token
      await supabase.from('user_push_tokens').upsert({
        'user_id': userId,
        'user_type': 'customer',
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');

      debugPrint('Push token saved successfully');
    } catch (e) {
      debugPrint('Error saving push token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');

    // Extract title and body
    final title = message.data['title'] ??
                  message.notification?.title ??
                  'New Notification';
    final body = message.data['body'] ??
                 message.notification?.body ??
                 '';

    // Show local notification
    _showLocalNotification(
      title: title,
      body: body,
      payload: message.data['notification_id'],
    );

    // Increment unread count and notify listeners
    _unreadCount++;
    notifyListeners();

    // Also refresh notifications list in background
    loadNotifications();
  }

  /// Load unread notification count
  Future<void> loadUnreadCount() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Count individual unread notifications
      final individualResponse = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .eq('is_mass_notification', false);

      // Count unread mass notification receipts
      final massResponse = await supabase
          .from('mass_notification_receipts')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      _unreadCount = (individualResponse as List).length + (massResponse as List).length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  /// Load all notifications
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get individual notifications
      final individualResponse = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .eq('is_mass_notification', false)
          .order('created_at', ascending: false)
          .limit(50);

      // Get mass notifications with read status
      final massResponse = await supabase
          .from('mass_notification_receipts')
          .select('*, notifications(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      // Combine and sort
      final List<Map<String, dynamic>> allNotifications = [];

      for (final notification in (individualResponse as List)) {
        allNotifications.add({
          ...Map<String, dynamic>.from(notification),
          'is_mass': false,
        });
      }

      for (final receipt in (massResponse as List)) {
        final notification = receipt['notifications'];
        if (notification != null) {
          allNotifications.add({
            ...Map<String, dynamic>.from(notification),
            'is_mass': true,
            'is_read': receipt['is_read'],
            'receipt_id': receipt['id'],
          });
        }
      }

      // Sort by created_at
      allNotifications.sort((a, b) {
        final aDate = DateTime.parse(a['created_at']);
        final bDate = DateTime.parse(b['created_at']);
        return bDate.compareTo(aDate);
      });

      _notifications = allNotifications;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(Map<String, dynamic> notification) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      if (notification['is_mass'] == true) {
        // Mark mass notification receipt as read
        await supabase
            .from('mass_notification_receipts')
            .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
            .eq('id', notification['receipt_id']);
      } else {
        // Mark individual notification as read
        await supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('id', notification['id']);
      }

      // Update local state
      final index = _notifications.indexWhere((n) => n['id'] == notification['id']);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
      }
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Mark individual notifications
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      // Mark mass notification receipts
      await supabase
          .from('mass_notification_receipts')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('is_read', false);

      // Update local state
      for (var notification in _notifications) {
        notification['is_read'] = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  /// Delete push token on logout
  Future<void> deleteToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await supabase
            .from('user_push_tokens')
            .delete()
            .eq('token', token);
      }
    } catch (e) {
      debugPrint('Error deleting push token: $e');
    }
  }

  /// Get notification preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('notification_preferences')
          .select('*')
          .eq('user_id', userId)
          .eq('user_type', 'customer')
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error getting preferences: $e');
      return null;
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('notification_preferences').upsert({
        'user_id': userId,
        'user_type': 'customer',
        ...preferences,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,user_type');

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating preferences: $e');
    }
  }

  /// Clear all local data (for logout)
  void clear() {
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }
}
