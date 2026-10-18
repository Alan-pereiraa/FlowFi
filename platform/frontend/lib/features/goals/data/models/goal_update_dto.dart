import '../../../../shared/utils/date_labels.dart';
import '../../../../shared/utils/money.dart';
import '../../domain/entities/goal_update.dart';

/// Body of `PATCH /goals/{id}`.
class GoalUpdateDto {
  const GoalUpdateDto(this.data);

  final GoalUpdate data;

  Map<String, dynamic> toJson() => {
    'name': data.name,
    'icon': data.icon,
    'color': data.color,
    'target_amount': Money.toApi(data.targetCents),
    // An explicit null is what clears an existing deadline on PATCH.
    'expires_at': data.expiresAt == null
        ? null
        : DateLabels.toApi(data.expiresAt!),
  };
}
