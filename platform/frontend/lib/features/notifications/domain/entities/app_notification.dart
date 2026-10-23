import 'package:flutter/foundation.dart';

import 'notification_type.dart';

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.subject,
    this.subjectId,
    this.readAt,
  });

  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final String? subject;
  final int? subjectId;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  AppNotification markedRead(DateTime at) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    createdAt: createdAt,
    subject: subject,
    subjectId: subjectId,
    readAt: readAt ?? at,
  );

  @override
  bool operator ==(Object other) =>
      other is AppNotification &&
      other.id == id &&
      other.title == title &&
      other.message == message &&
      other.type == type &&
      other.subject == subject &&
      other.subjectId == subjectId &&
      other.readAt == readAt &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    message,
    type,
    subject,
    subjectId,
    readAt,
    createdAt,
  );
}
