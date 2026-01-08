import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:canoto/providers/notification_provider.dart';
import 'package:intl/intl.dart';

/// Notifications Screen - Display all notifications and alerts
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Thông báo'),
                if (provider.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // Connection status
              _buildConnectionStatus(provider),
              const SizedBox(width: 8),
              // Mark all as read
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'Đánh dấu tất cả đã đọc',
                onPressed: provider.markAllAsRead,
              ),
              // Clear all
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'clear_notifications') {
                    provider.clearAll();
                  } else if (value == 'clear_alerts') {
                    provider.clearAllAlerts();
                  } else if (value == 'reconnect') {
                    provider.reconnect();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_notifications',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep),
                        SizedBox(width: 8),
                        Text('Xóa tất cả thông báo'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_alerts',
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber),
                        SizedBox(width: 8),
                        Text('Xóa tất cả cảnh báo'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'reconnect',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Kết nối lại'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications),
                      const SizedBox(width: 8),
                      const Text('Thông báo'),
                      if (provider.notifications.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${provider.notifications.length}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber),
                      const SizedBox(width: 8),
                      const Text('Cảnh báo'),
                      if (provider.alerts.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${provider.alerts.length}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Notifications Tab
              _buildNotificationsList(provider.notifications, provider),
              // Alerts Tab
              _buildAlertsList(provider.alerts, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatus(NotificationProvider provider) {
    final isConnected = provider.isConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.shade400 : Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Online' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    List<AppNotification> notifications,
    NotificationProvider provider,
  ) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có thông báo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification, provider);
      },
    );
  }

  Widget _buildNotificationCard(
    AppNotification notification,
    NotificationProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification.isRead ? null : Colors.blue.shade50,
      child: InkWell(
        onTap: () => provider.markAsRead(notification.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
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
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(notification.timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => provider.clearNotification(notification.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsList(
    List<AppNotification> alerts,
    NotificationProvider provider,
  ) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có cảnh báo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(alert, provider);
      },
    );
  }

  Widget _buildAlertCard(
    AppNotification alert,
    NotificationProvider provider,
  ) {
    Color alertColor;
    IconData alertIcon;
    
    switch (alert.priority) {
      case AppNotificationPriority.critical:
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case AppNotificationPriority.high:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      case AppNotificationPriority.low:
        alertColor = Colors.grey;
        alertIcon = Icons.info_outline;
        break;
      default:
        alertColor = Colors.amber;
        alertIcon = Icons.warning_amber;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: alertColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              alertColor.withValues(alpha: 0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  alertIcon,
                  color: alertColor,
                  size: 28,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: alertColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPriorityText(alert.priority),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(alert.timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.message,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => provider.clearAlert(alert.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPriorityText(AppNotificationPriority priority) {
    switch (priority) {
      case AppNotificationPriority.critical:
        return 'NGUY HIỂM';
      case AppNotificationPriority.high:
        return 'CAO';
      case AppNotificationPriority.low:
        return 'THẤP';
      default:
        return 'BÌNH THƯỜNG';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
  }
}
