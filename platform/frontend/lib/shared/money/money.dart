import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// An amount in integer cents. The API speaks decimal strings (`"1500.00"`);
/// never go through `double`.
@immutable
class Money implements Comparable<Money> {
  const Money(this.cents);

  static const zero = Money(0);

  /// Parses the API's decimal string (`"1500.00"`, `"12.5"`, `"7"`).
  factory Money.parse(String decimal) {
    final trimmed = decimal.trim();
    final negative = trimmed.startsWith('-');
    final unsigned = negative ? trimmed.substring(1) : trimmed;
    final parts = unsigned.split('.');
    if (parts.length > 2 || parts.first.isEmpty) {
      throw FormatException('Invalid money string', decimal);
    }
    final units = int.parse(parts.first);
    final fraction = parts.length == 2
        ? int.parse(parts[1].padRight(2, '0').substring(0, 2))
        : 0;
    final cents = units * 100 + fraction;
    return Money(negative ? -cents : cents);
  }

  final int cents;

  bool get isZero => cents == 0;

  Money operator +(Money other) => Money(cents + other.cents);

  Money operator -(Money other) => Money(cents - other.cents);

  /// Decimal string the API accepts: `"1500.00"`.
  String toDecimal() {
    final sign = cents < 0 ? '-' : '';
    final abs = cents.abs();
    final fraction = (abs % 100).toString().padLeft(2, '0');
    return '$sign${abs ~/ 100}.$fraction';
  }

  static final _thousands = NumberFormat.decimalPattern('pt_BR');

  /// `R$ 1.234,56`.
  String format() => 'R\$ ${formatDigits()}';

  /// `1.234,56`, without the currency symbol (for the big amount field).
  /// Built from integer parts so no `double` is ever involved.
  String formatDigits() {
    final abs = cents.abs();
    final units = _thousands.format(abs ~/ 100);
    final fraction = (abs % 100).toString().padLeft(2, '0');
    return '${cents < 0 ? '-' : ''}$units,$fraction';
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => 'Money(${toDecimal()})';
}
