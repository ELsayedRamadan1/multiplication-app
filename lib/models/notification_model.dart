import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'assignment', 'result', 'system', 'assignment_completed'
  final String? assignmentId;
  final String? studentId; // when notification targets a student this is the recipient
  final String? teacherId; // when notification targets a teacher this is the recipient
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.assignmentId,
    this.studentId,
    this.teacherId,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'teacherId': teacherId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // createdAt in Firestore may be a Timestamp or stored as ISO string
    DateTime parsedCreatedAt;
    final created = json['createdAt'];
    try {
      if (created == null) {
        parsedCreatedAt = DateTime.now();
      } else if (created is String) {
        parsedCreatedAt = DateTime.parse(created);
      } else if (created is DateTime) {
        parsedCreatedAt = created;
      } else if (created is Map && created['_seconds'] != null) {
        // server timestamp serialized (rare)
        parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch((created['_seconds'] as int) * 1000);
      } else if (created is Timestamp) {
        // Firestore Timestamp
        parsedCreatedAt = created.toDate();
      } else {
        parsedCreatedAt = DateTime.now();
      }
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      assignmentId: json['assignmentId'],
      studentId: json['studentId'],
      teacherId: json['teacherId'],
      createdAt: parsedCreatedAt,
      isRead: json['isRead'] ?? false,
    );
  }
}
