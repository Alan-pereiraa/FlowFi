/// Money is handled as integer cents inside the client; the API speaks
/// two-decimal strings ("1500.00"). Never use `double` for an amount.
abstract final class Money {
  static final _apiDecimal = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$');

  /// "1500.5" -> 150050. Null when [value] is null or not a non-negative
  /// decimal with at most two places.
  static int? parseApi(String? value) {
    if (value == null) return null;
    final match = _apiDecimal.firstMatch(value.trim());
    if (match == null) return null;
    final whole = int.tryParse(match.group(1)!);
    final fraction = int.tryParse((match.group(2) ?? '').padRight(2, '0'));
    if (whole == null || fraction == null) return null;
    return whole * 100 + fraction;
  }

  /// 150050 -> "1500.50" (the format the API accepts).
  static String toApi(int cents) {
    final sign = cents < 0 ? '-' : '';
    final abs = cents.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  /// 150050 -> "R$ 1.500,50". The space after the symbol is non-breaking so
  /// a value never wraps between "R$" and the number.
  ///
  /// [dropZeroCents] renders whole amounts as "R$ 4.500", as the goal cards do.
  static String format(
    int cents, {
    bool symbol = true,
    bool dropZeroCents = false,
  }) {
    final abs = cents.abs();
    final whole = _group((abs ~/ 100).toString());
    final fraction = abs % 100;
    final number = dropZeroCents && fraction == 0
        ? whole
        : '$whole,${fraction.toString().padLeft(2, '0')}';
    final signed = cents < 0 ? '-$number' : number;
    return symbol ? 'R\$ $signed' : signed;
  }

  static String _group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
