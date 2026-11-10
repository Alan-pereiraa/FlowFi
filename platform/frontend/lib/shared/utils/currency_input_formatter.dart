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
    final oldText = oldValue.text;
    final newText = newValue.text;
    final oldDigits = _significantDigits(oldText);
    final newDigits = _significantDigits(newText);
    final selection = oldValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return newDigits;

    final added = newText.length - oldText.length;
    if (added > 0) {
      final start = selection.start;
      final insertedAtCaret =
          start <= oldText.length &&
          newText.startsWith(oldText.substring(0, start)) &&
          newText.endsWith(oldText.substring(start));
      if (!insertedAtCaret) return newDigits;
      return _significantDigits(
        oldDigits + newText.substring(start, start + added),
      );
    }

    if (added == 0) return newText == oldText ? oldDigits : newDigits;

    var prefix = 0;
    while (prefix < newText.length && newText[prefix] == oldText[prefix]) {
      prefix++;
    }
    if (!oldText.endsWith(newText.substring(prefix))) return newDigits;

    final removed =
        oldText.replaceAll(RegExp(r'\D'), '').length -
        newText.replaceAll(RegExp(r'\D'), '').length;
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
