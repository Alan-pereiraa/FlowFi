import 'package:flutter/services.dart';

import 'money.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  const CurrencyInputFormatter();

  static const maxCents = 9999999999;

  static int centsOf(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    final cents = int.tryParse(digits) ?? 0;
    return cents > maxCents ? maxCents : cents;
  }

  static String textOf(int cents) =>
      cents <= 0 ? '' : Money.format(cents, symbol: false);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final cents = int.tryParse(digits) ?? 0;
    if (digits.length > 10 || cents > maxCents) return oldValue;

    final text = textOf(cents);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
