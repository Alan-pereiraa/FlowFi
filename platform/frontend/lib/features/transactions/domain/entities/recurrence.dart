import 'package:flutter/foundation.dart';

@immutable
class Recurrence {
  const Recurrence({
    required this.periodUnit,
    required this.periodInterval,
    required this.generatedCount,
    this.endDate,
    this.occurrences,
    this.nextOccurrenceOn,
  });

  final String periodUnit;
  final int periodInterval;
  final int generatedCount;
  final DateTime? endDate;
  final int? occurrences;
  final DateTime? nextOccurrenceOn;

  bool get active => nextOccurrenceOn != null;
}
