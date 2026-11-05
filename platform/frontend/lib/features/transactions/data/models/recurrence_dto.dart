import '../../../../shared/utils/dates.dart';
import '../../domain/entities/recurrence.dart';

abstract final class RecurrenceDto {
  static Recurrence fromJson(Map<String, dynamic> json) {
    final endDate = json['end_date'] as String?;
    final next = json['next_occurrence_on'] as String?;
    return Recurrence(
      periodUnit: json['period_unit'] as String,
      periodInterval: json['period_interval'] as int,
      generatedCount: json['generated_count'] as int,
      endDate: endDate == null ? null : Dates.fromApi(endDate),
      occurrences: json['occurrences'] as int?,
      nextOccurrenceOn: next == null ? null : Dates.fromApi(next),
    );
  }
}
