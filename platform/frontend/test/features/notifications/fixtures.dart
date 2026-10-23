Map<String, dynamic> notificationJson({
  int id = 1,
  String type = 'warning',
  String? readAt,
  String subject = 'category_limit_warning',
}) => {
  'id': id,
  'title': 'Category limit warning',
  'message': 'You have spent over 80% of your limit for the category "Food".',
  'type': type,
  'subject': subject,
  'subject_id': 3,
  'read_at': readAt,
  'created_at': '2026-10-22T12:00:00.000000Z',
  'updated_at': '2026-10-22T12:00:00.000000Z',
};
