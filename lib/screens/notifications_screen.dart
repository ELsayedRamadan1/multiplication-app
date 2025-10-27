import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.markAllNotificationsAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.blue.shade800,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark All Read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return FutureBuilder<List<NotificationModel>>(
              future: userProvider.getUserNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading notifications',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                List<NotificationModel> notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notifications yet.\nCheck back later!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    NotificationModel notification = notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getNotificationColor(notification.type),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.message),
                            Text(
                              _formatDate(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        trailing: notification.isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                        onTap: () {
                          userProvider.markNotificationAsRead(notification.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification marked as read')),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'assignment':
        return Colors.green;
      case 'result':
        return Colors.blue;
      case 'system':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment;
      case 'result':
        return Icons.grade;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} ${'minutes ago'}';
      }
      return '${difference.inHours} ${'hours ago'}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
