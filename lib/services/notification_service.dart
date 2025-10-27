import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const String _key = 'notifications';

  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList(_key) ?? [];
    List<NotificationModel> allNotifications = data.map((e) => NotificationModel.fromJson(jsonDecode(e))).toList();

    return allNotifications.where((notification) => notification.studentId == userId).toList();
  }

  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    String? assignmentId,
    String? studentId,
  }) async {
    NotificationModel notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      assignmentId: assignmentId,
      studentId: studentId,
    );

    await _saveNotification(notification);
  }

  Future<void> markAsRead(String notificationId) async {
    List<NotificationModel> notifications = await getAllNotifications();
    int index = notifications.indexWhere((n) => n.id == notificationId);

    if (index != -1) {
      notifications[index] = NotificationModel(
        id: notifications[index].id,
        title: notifications[index].title,
        message: notifications[index].message,
        type: notifications[index].type,
        assignmentId: notifications[index].assignmentId,
        studentId: notifications[index].studentId,
        createdAt: notifications[index].createdAt,
        isRead: true,
      );

      await _saveAllNotifications(notifications);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    List<NotificationModel> notifications = await getAllNotifications();
    bool hasChanges = false;

    for (int i = 0; i < notifications.length; i++) {
      if (notifications[i].studentId == userId && !notifications[i].isRead) {
        notifications[i] = NotificationModel(
          id: notifications[i].id,
          title: notifications[i].title,
          message: notifications[i].message,
          type: notifications[i].type,
          assignmentId: notifications[i].assignmentId,
          studentId: notifications[i].studentId,
          createdAt: notifications[i].createdAt,
          isRead: true,
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveAllNotifications(notifications);
    }
  }

  Future<List<NotificationModel>> getAllNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList(_key) ?? [];
    return data.map((e) => NotificationModel.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _saveNotification(NotificationModel notification) async {
    List<NotificationModel> notifications = await getAllNotifications();
    notifications.add(notification);
    await _saveAllNotifications(notifications);
  }

  Future<void> _saveAllNotifications(List<NotificationModel> notifications) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_key, data);
  }

  Future<void> clearNotificationsForUser(String userId) async {
    List<NotificationModel> notifications = await getAllNotifications();
    notifications.removeWhere((n) => n.studentId == userId);
    await _saveAllNotifications(notifications);
  }
}
