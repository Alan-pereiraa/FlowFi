import 'package:flutter/foundation.dart' show immutable;

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_filter.dart';

@immutable
class NotificationListState {
  const NotificationListState({
    this.filter = NotificationFilter.all,
    this.items = const [],
    this.loading = false,
    this.loaded = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.page = 0,
    this.errorMessage,
  });

  final NotificationFilter filter;
  final List<AppNotification> items;
  final bool loading;
  final bool loaded;
  final bool loadingMore;
  final bool hasMore;
  final int page;
  final String? errorMessage;

  bool get showSpinner => loading && !loaded;

  bool get showError => !loaded && !loading && errorMessage != null;

  NotificationListState copyWith({
    List<AppNotification>? items,
    bool? loading,
    bool? loaded,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    String? Function()? errorMessage,
  }) {
    return NotificationListState(
      filter: filter,
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loaded: loaded ?? this.loaded,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: errorMessage == null ? this.errorMessage : errorMessage(),
    );
  }
}
