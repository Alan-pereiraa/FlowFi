import 'package:flutter/services.dart';

import 'money.dart';

/// Cents-first currency mask: typing `1`, `5`, `0`, `0` yields `15,00`.
/// The field is empty (hint visible) while the value is zero.
class CurrencyInputFormatter extends TextInputFormatter {
  const CurrencyInputFormatter();

  /// 99.999.999,99, the ceiling the API accepts.
  static const maxCents = 9999999999;

  /// Value of a masked [text] in cents. Empty or garbage is zero.
  static int centsOf(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    final cents = int.tryParse(digits) ?? 0;
    return cents > maxCents ? maxCents : cents;
  }

  /// Masked text for [cents]; empty for zero.
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
