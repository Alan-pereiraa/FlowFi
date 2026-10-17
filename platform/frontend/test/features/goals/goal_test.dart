import 'package:flowfi_app/features/goals/domain/entities/goal.dart';
import 'package:flutter_test/flutter_test.dart';

Goal goal({
  int target = 600000,
  int current = 0,
  DateTime? expiresAt,
}) => Goal(
  id: 1,
  name: 'Viagem',
  icon: 'flight',
  color: '#00530C',
  targetCents: target,
  currentCents: current,
  expiresAt: expiresAt,
);

void main() {
  group('progress', () {
    test('percent rounds down so it never reads 100% early', () {
      expect(goal(target: 10000, current: 9999).percent, 99);
      expect(goal(target: 10000, current: 10000).percent, 100);
      expect(goal(target: 10000, current: 29).percent, 0);
    });

    test('integer math: 29% of the target is 29, not 28', () {
      expect(goal(target: 100, current: 29).percent, 29);
    });

    test('is clamped to 0..100 and survives a zero target', () {
      expect(goal(target: 10000, current: 99999).percent, 100);
      expect(goal(target: 10000, current: 99999).progress, 1);
      expect(goal(target: 0, current: 5).percent, 0);
      expect(goal(target: 0, current: 5).progress, 0);
    });

    test('matches the mock-up: R\$ 4.500 of R\$ 6.000 is 75%', () {
      expect(goal(target: 600000, current: 450000).percent, 75);
    });
  });

  group('monthlyContributionCents', () {
    final now = DateTime(2026, 10, 16);

    test('open-ended or reached goals have no suggestion', () {
      expect(goal().monthlyContributionCents(now), isNull);
      expect(
        goal(
          target: 100,
          current: 100,
          expiresAt: DateTime(2027, 1, 1),
        ).monthlyContributionCents(now),
        isNull,
      );
    });

    test('splits what is left over the months to the deadline, rounding up', () {
      // Dec 2026 is ~2.5 months away -> 3 months; (500000 - 350000) / 3.
      final g = goal(
        target: 500000,
        current: 350000,
        expiresAt: DateTime(2026, 12, 31),
      );
      expect(g.monthlyContributionCents(now), 50000);
    });

    test('a deadline that is today or past counts as one month', () {
      final g = goal(
        target: 10000,
        current: 2500,
        expiresAt: DateTime(2026, 10, 16),
      );
      expect(g.monthlyContributionCents(now), 7500);
      expect(
        goal(
          target: 10000,
          current: 2500,
          expiresAt: DateTime(2020, 1, 1),
        ).monthlyContributionCents(now),
        7500,
      );
    });

    test('rounds up so the sum of the months always covers the goal', () {
      final g = goal(
        target: 1000,
        current: 0,
        expiresAt: DateTime(2026, 12, 31),
      );
      final monthly = g.monthlyContributionCents(now)!;
      expect(monthly * 3, greaterThanOrEqualTo(1000));
    });
  });
}
