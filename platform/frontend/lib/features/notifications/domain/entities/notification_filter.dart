/// Which notifications the list shows. [status] is the API's `status` query
/// value; `null` means no filter.
enum NotificationFilter {
  all(label: 'Todas', status: null),
  unread(label: 'Não lidas', status: 'unread'),
  read(label: 'Lidas', status: 'read');

  const NotificationFilter({required this.label, required this.status});

  final String label;
  final String? status;
}
