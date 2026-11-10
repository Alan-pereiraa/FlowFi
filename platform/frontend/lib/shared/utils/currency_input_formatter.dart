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

  static String editedDigits(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = _significantDigits(oldValue.text);
    final newDigits = _significantDigits(newValue.text);
    final selection = oldValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return newDigits;

    final added = newValue.text.length - oldValue.text.length;
    if (added > 0) {
      final start = selection.start.clamp(0, newValue.text.length);
      final end = (start + added).clamp(start, newValue.text.length);
      return _significantDigits(
        oldDigits + newValue.text.substring(start, end),
      );
    }

    final removed =
        oldValue.text.replaceAll(RegExp(r'\D'), '').length -
        newValue.text.replaceAll(RegExp(r'\D'), '').length;
    if (removed <= 0) return oldDigits;
    return oldDigits.substring(
      0,
      (oldDigits.length - removed).clamp(0, oldDigits.length),
    );
  }

  static String _significantDigits(String text) =>
      text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = editedDigits(oldValue, newValue);
    final cents = int.tryParse(digits) ?? 0;
    if (digits.length > 10 || cents > maxCents) return oldValue;

    final text = textOf(cents);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
