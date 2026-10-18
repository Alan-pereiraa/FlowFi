import 'package:flowfi_app/shared/utils/currency_input_formatter.dart';
import 'package:flowfi_app/shared/utils/date_labels.dart';
import 'package:flowfi_app/shared/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('parseApi reads the API decimal strings into cents', () {
      expect(Money.parseApi('1500.00'), 150000);
      expect(Money.parseApi('1500.5'), 150050);
      expect(Money.parseApi('0.01'), 1);
      expect(Money.parseApi('200'), 20000);
    });

    test('parseApi rejects anything that is not a plain decimal', () {
      expect(Money.parseApi(null), isNull);
      expect(Money.parseApi(''), isNull);
      expect(Money.parseApi('abc'), isNull);
      expect(Money.parseApi('1.234'), isNull);
      expect(Money.parseApi('-5.00'), isNull);
    });

    test('toApi always writes two decimals', () {
      expect(Money.toApi(150050), '1500.50');
      expect(Money.toApi(5), '0.05');
      expect(Money.toApi(20000), '200.00');
    });

    test('format groups thousands and uses a comma', () {
      expect(Money.format(150050), 'R\$ 1.500,50');
      expect(Money.format(0), 'R\$ 0,00');
      expect(Money.format(123456789), 'R\$ 1.234.567,89');
      expect(Money.format(150050, symbol: false), '1.500,50');
    });

    test('dropZeroCents hides ",00" only for whole amounts', () {
      expect(Money.format(450000, dropZeroCents: true), 'R\$ 4.500');
      expect(Money.format(450050, dropZeroCents: true), 'R\$ 4.500,50');
    });
  });

  group('CurrencyInputFormatter', () {
    const formatter = CurrencyInputFormatter();

    TextEditingValue type(String from, String to) =>
        formatter.formatEditUpdate(
          TextEditingValue(text: from),
          TextEditingValue(text: to),
        );

    test('digits fill from the cents', () {
      expect(type('', '1').text, '0,01');
      expect(type('0,01', '0,015').text, '0,15');
      expect(type('0,15', '0,150').text, '1,50');
      expect(type('1,50', '1,500').text, '15,00');
    });

    test('deleting down to zero empties the field', () {
      expect(type('0,01', '0,0').text, '');
    });

    test('ignores pasted garbage and refuses to pass the API ceiling', () {
      expect(type('', 'R\$ 12a').text, '0,12');
      expect(type('99.999.999,99', '99.999.999,999').text, '99.999.999,99');
    });

    test('centsOf and textOf round-trip', () {
      expect(CurrencyInputFormatter.centsOf('1.500,50'), 150050);
      expect(CurrencyInputFormatter.centsOf(''), 0);
      expect(CurrencyInputFormatter.textOf(150050), '1.500,50');
      expect(CurrencyInputFormatter.textOf(0), '');
    });
  });

  group('DateLabels', () {
    test('formats for the screens and for the API', () {
      final date = DateTime(2026, 12, 5);
      expect(DateLabels.monthYear(date), 'Dez 2026');
      expect(DateLabels.full(date), '05/12/2026');
      expect(DateLabels.toApi(date), '2026-12-05');
    });

    test('parseApi reads a date or a full timestamp, never throws', () {
      expect(DateLabels.parseApi('2026-12-05'), DateTime(2026, 12, 5));
      expect(DateLabels.parseApi('2026-12-05T00:00:00.000000Z')?.day, 5);
      expect(DateLabels.parseApi(null), isNull);
      expect(DateLabels.parseApi('nope'), isNull);
    });
  });
}
