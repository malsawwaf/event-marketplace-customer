import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/notification_service.dart';
import '../../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              if (notificationService.unreadCount > 0) {
                return TextButton(
                  onPressed: () => notificationService.markAllAsRead(),
                  child: Text(
                    l10n.markAllAsRead,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          if (notificationService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationService.notifications.isEmpty) {
            return _buildEmptyState(l10n);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await notificationService.loadNotifications();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notificationService.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationService.notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noNotifications,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noNotificationsDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final notificationService = context.read<NotificationService>();

    // Mark as read
    if (notification['is_read'] != true) {
      notificationService.markAsRead(notification);
    }

    // Handle navigation based on notification type
    final type = notification['type'] as String?;
    final data = notification['data'] as Map<String, dynamic>?;

    switch (type) {
      case 'order_update':
      case 'new_order':
      case 'order_cancelled':
        // Navigate to order details if order_id is available
        final orderId = data?['order_id'];
        if (orderId != null) {
          // Navigator.push to order detail screen
          // For now, just show a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order: $orderId')),
          );
        }
        break;
      case 'promotion':
        // Could navigate to promotions or a specific item
        break;
      default:
        // Just mark as read, no navigation
        break;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['is_read'] == true;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Get title and body based on language
    final title = isArabic
        ? (notification['title_ar'] ?? notification['title_en'] ?? '')
        : (notification['title_en'] ?? notification['title_ar'] ?? '');
    final body = isArabic
        ? (notification['body_ar'] ?? notification['body_en'] ?? '')
        : (notification['body_en'] ?? notification['body_ar'] ?? '');

    final createdAt = notification['created_at'] != null
        ? DateTime.parse(notification['created_at'])
        : DateTime.now();

    final type = notification['type'] as String? ?? 'general';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: isRead ? 0 : 2,
      color: isRead ? Colors.white : Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.grey.shade200 : AppTheme.primaryNavy.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getIconColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getIconColor(type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatTimeAgo(createdAt, context),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_update':
      case 'new_order':
        return Icons.shopping_bag_outlined;
      case 'order_cancelled':
        return Icons.cancel_outlined;
      case 'promotion':
        return Icons.local_offer_outlined;
      case 'review':
        return Icons.star_outline;
      case 'price_drop':
        return Icons.trending_down;
      case 'new_item':
        return Icons.new_releases_outlined;
      case 'admin':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'order_update':
      case 'new_order':
        return Colors.blue;
      case 'order_cancelled':
        return Colors.red;
      case 'promotion':
        return Colors.orange;
      case 'review':
        return Colors.amber;
      case 'price_drop':
        return Colors.green;
      case 'new_item':
        return Colors.purple;
      case 'admin':
        return AppTheme.primaryNavy;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inMinutes < 60) {
      return l10n.minutesAgo2(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo2(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo2(difference.inDays);
    } else {
      // Format as date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
