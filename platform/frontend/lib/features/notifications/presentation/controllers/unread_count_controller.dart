import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../identity/presentation/controllers/session_controller.dart';
import '../../data/repositories/notification_repository_impl.dart';

final unreadCountControllerProvider =
    NotifierProvider<UnreadCountController, int>(UnreadCountController.new);

class UnreadCountController extends Notifier<int> {
  int _generation = 0;

  @override
  int build() {
    final userId = ref.watch(
      sessionControllerProvider.select((s) => s.user?.id),
    );
    if (userId != null) Future.microtask(refresh);
    return 0;
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    try {
      final count = await ref
          .read(notificationRepositoryProvider)
          .unreadCount();
      if (!ref.mounted || generation != _generation) return;
      state = count;
    } on Failure {
      return;
    }
  }
}
