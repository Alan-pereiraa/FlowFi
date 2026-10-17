import '../../../../shared/utils/date_labels.dart';
import '../../../../shared/utils/money.dart';
import '../../domain/entities/new_goal.dart';

/// Body of `POST /goals`. The initial amount is not part of it.
class NewGoalDto {
  const NewGoalDto(this.data);

  final NewGoal data;

  Map<String, dynamic> toJson() => {
    'name': data.name,
    'icon': data.icon,
    'color': data.color,
    'target_amount': Money.toApi(data.targetCents),
    if (data.expiresAt != null) 'expires_at': DateLabels.toApi(data.expiresAt!),
  };
}
