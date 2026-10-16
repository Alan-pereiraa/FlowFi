import 'package:flowfi_app/shared/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses API decimal strings into cents', () {
    expect(Money.parse('1500.00').cents, 150000);
    expect(Money.parse('12.5').cents, 1250);
    expect(Money.parse('7').cents, 700);
    expect(Money.parse('0.01').cents, 1);
    expect(Money.parse('-45.90').cents, -4590);
  });

  test('rejects malformed strings', () {
    expect(() => Money.parse('1.2.3'), throwsFormatException);
    expect(() => Money.parse('.50'), throwsFormatException);
  });

  test('serializes back to the API format', () {
    expect(const Money(150000).toDecimal(), '1500.00');
    expect(const Money(5).toDecimal(), '0.05');
    expect(const Money(-4590).toDecimal(), '-45.90');
  });

  test('formats as pt-BR currency', () {
    expect(const Money(123456).format(), r'R$ 1.234,56');
    expect(const Money(0).format(), r'R$ 0,00');
    expect(const Money(9999999999).formatDigits(), '99.999.999,99');
  });
}
