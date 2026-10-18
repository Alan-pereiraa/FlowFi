/// pt-BR date text built by hand, so it never depends on `intl` locale data
/// having been loaded (it is not, in unit tests).
abstract final class DateLabels {
  static const _months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  /// "Dez 2026".
  static String monthYear(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';

  /// "05/12/2026".
  static String full(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

  /// "2026-12-05", the format the API takes.
  static String toApi(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  /// "2026-12-05" -> local midnight of that day. Null when unreadable.
  static DateTime? parseApi(String? value) {
    if (value == null || value.length < 10) return null;
    return DateTime.tryParse(value.substring(0, 10));
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
