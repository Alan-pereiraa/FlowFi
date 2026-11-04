import '../../../../shared/money/money.dart';
import '../../../../shared/utils/dates.dart';
import '../../domain/entities/transaction_draft.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionDraftDto {
  const TransactionDraftDto({
    required this.transcript,
    required this.kind,
    required this.draft,
  });

  factory TransactionDraftDto.fromJson(Map<String, dynamic> json) =>
      TransactionDraftDto(
        transcript: json['transcript'] as String? ?? '',
        kind: json['kind'] as String? ?? 'transaction',
        draft: json['draft'] as Map<String, dynamic>? ?? const {},
      );

  final String transcript;
  final String kind;
  final Map<String, dynamic> draft;

  TransactionDraft toEntity() {
    final recurring = kind == 'recurring';
    final amount = (recurring ? draft['amount'] : draft['total_amount'])
        ?.toString();
    final date = (recurring ? draft['start_date'] : draft['date']) as String?;
    final endDate = draft['end_date'] as String?;
    return TransactionDraft(
      transcript: transcript,
      recurring: recurring,
      type: _type(draft['type'] as String?),
      amount: amount == null ? null : Money.parse(amount),
      date: date == null ? null : Dates.fromApi(date),
      description: draft['description'] as String?,
      categoryId: draft['category_id'] as int?,
      goalId: draft['goal_id'] as int?,
      installmentsCount: draft['installments_count'] as int?,
      periodUnit: draft['period_unit'] as String?,
      periodInterval: draft['period_interval'] as int?,
      occurrences: draft['occurrences'] as int?,
      endDate: endDate == null ? null : Dates.fromApi(endDate),
    );
  }

  static TransactionType _type(String? value) {
    for (final type in TransactionType.values) {
      if (type.apiValue == value) return type;
    }
    return TransactionType.expense;
  }
}
