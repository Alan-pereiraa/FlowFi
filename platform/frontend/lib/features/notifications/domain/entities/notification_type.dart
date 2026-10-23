enum NotificationType {
  info('info'),
  success('success'),
  warning('warning'),
  error('error');

  const NotificationType(this.apiValue);

  final String apiValue;

  static NotificationType fromApi(String value) => values.firstWhere(
    (type) => type.apiValue == value,
    orElse: () => NotificationType.info,
  );
}
