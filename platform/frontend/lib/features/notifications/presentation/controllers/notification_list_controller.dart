import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/clock.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import 'notification_list_state.dart';
import 'unread_count_controller.dart';

final notificationListControllerProvider =
    NotifierProvider.autoDispose<
      NotificationListController,
      NotificationListState
    >(NotificationListController.new);

class NotificationListController extends Notifier<NotificationListState> {
  static const perPage = 20;

  int _generation = 0;

  @override
  NotificationListState build() {
    Future.microtask(refresh);
    return const NotificationListState(loading: true);
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    state = state.copyWith(loading: true, errorMessage: () => null);
    try {
      final page = await ref
          .read(notificationRepositoryProvider)
          .list(perPage: perPage);
      if (!ref.mounted || generation != _generation) return;
      state = NotificationListState(
        items: page.items,
        loaded: true,
        hasMore: page.hasMore,
        page: page.currentPage,
      );
    } on Failure catch (failure) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        loading: false,
        errorMessage: () => ErrorMessages.general(failure),
      );
    }
    _refreshBadge();
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await ref
          .read(notificationRepositoryProvider)
          .list(page: state.page + 1, perPage: perPage);
      if (!ref.mounted || generation != _generation) return;
      final known = {for (final item in state.items) item.id};
      state = state.copyWith(
        items: [
          ...state.items,
          ...page.items.where((item) => !known.contains(item.id)),
        ],
        page: page.currentPage,
        hasMore: page.hasMore,
        loadingMore: false,
      );
    } on Failure {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(loadingMore: false);
    }
  }

  Future<String?> markAsRead(int id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0 || state.items[index].isRead) return null;
    final original = state.items[index];
    _replace(id, original.markedRead(ref.read(clockProvider)()));
    try {
      final updated = await ref
          .read(notificationRepositoryProvider)
          .markAsRead(id);
      if (!ref.mounted) return null;
      _replace(id, updated);
      _refreshBadge();
      return null;
    } on Failure catch (failure) {
      if (!ref.mounted) return null;
      _replace(id, original);
      return ErrorMessages.general(failure);
    }
  }

  Future<String?> delete(int id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0) return null;
    final removed = state.items[index];
    state = state.copyWith(items: [...state.items]..removeAt(index));
    try {
      await ref.read(notificationRepositoryProvider).delete(id);
      if (!ref.mounted) return null;
      _refreshBadge();
      return null;
    } on NotFoundFailure {
      return null;
    } on Failure catch (failure) {
      if (!ref.mounted) return null;
      final items = [...state.items];
      items.insert(index.clamp(0, items.length), removed);
      state = state.copyWith(items: items);
      return ErrorMessages.general(failure);
    }
  }

  void _replace(int id, AppNotification notification) {
    state = state.copyWith(
      items: [
        for (final item in state.items) item.id == id ? notification : item,
      ],
    );
  }

  void _refreshBadge() {
    if (!ref.mounted) return;
    ref.read(unreadCountControllerProvider.notifier).refresh();
  }
}
