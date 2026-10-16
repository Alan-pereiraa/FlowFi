import 'package:flowfi_app/shared/utils/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 24, 15, 30);

  test('API date round trip', () {
    expect(Dates.fromApi('2026-03-05'), DateTime(2026, 3, 5));
    expect(Dates.toApi(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
  });

  test('input format is dd/MM/yyyy', () {
    expect(Dates.input(DateTime(2026, 8, 1)), '01/08/2026');
  });

  test('day headers', () {
    expect(
      Dates.dayHeader(DateTime(2026, 10, 24), today: today),
      'Hoje, 24 de outubro',
    );
    expect(
      Dates.dayHeader(DateTime(2026, 10, 23), today: today),
      'Ontem, 23 de outubro',
    );
    expect(
      Dates.dayHeader(DateTime(2026, 10, 2), today: today),
      '2 de outubro',
    );
    expect(
      Dates.dayHeader(DateTime(2025, 12, 31), today: today),
      '31 de dezembro de 2025',
    );
  });

  test('"Ontem" across a month boundary', () {
    expect(
      Dates.dayHeader(DateTime(2026, 2, 28), today: DateTime(2026, 3)),
      'Ontem, 28 de fevereiro',
    );
  });
}
