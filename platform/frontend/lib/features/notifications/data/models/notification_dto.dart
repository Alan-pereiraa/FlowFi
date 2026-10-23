import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_type.dart';

class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.subject,
    this.subjectId,
    this.readAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      NotificationDto(
        id: json['id'] as int,
        title: json['title'] as String,
        message: json['message'] as String,
        type: json['type'] as String,
        subject: json['subject'] as String?,
        subjectId: json['subject_id'] as int?,
        readAt: json['read_at'] as String?,
        createdAt: json['created_at'] as String,
      );

  final int id;
  final String title;
  final String message;
  final String type;
  final String? subject;
  final int? subjectId;
  final String? readAt;
  final String createdAt;

  AppNotification toEntity() => AppNotification(
    id: id,
    title: title,
    message: message,
    type: NotificationType.fromApi(type),
    subject: subject,
    subjectId: subjectId,
    readAt: readAt == null ? null : DateTime.parse(readAt!).toLocal(),
    createdAt: DateTime.parse(createdAt).toLocal(),
  );
}
