import 'package:flutter/services.dart';

/// Formats Brazilian phone digits as `(42) 99813-3757` / `(42) 3222-1111`.
class PhoneInputFormatter extends TextInputFormatter {
  static const maxDigits = 11;

  /// Formats raw digits for display (e.g. a stored `phone_number`).
  static String format(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    final buffer = StringBuffer('(');
    buffer.write(d.substring(0, d.length.clamp(0, 2)));
    if (d.length <= 2) return buffer.toString();
    buffer.write(') ');
    final rest = d.substring(2);
    // 9-digit mobile numbers split 5-4; landlines split 4-4.
    final splitAt = d.length == maxDigits ? 5 : 4;
    if (rest.length <= splitAt) {
      buffer.write(rest);
    } else {
      buffer
        ..write(rest.substring(0, splitAt))
        ..write('-')
        ..write(rest.substring(splitAt));
    }
    return buffer.toString();
  }

  static String digitsOf(String text) => text.replaceAll(RegExp(r'\D'), '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = digitsOf(newValue.text);
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final text = format(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
