/// pt-BR date formats used across screens. Built by hand so they don't depend
/// on intl's locale data being loaded.
abstract final class Dates {
  static const _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// `2026-10-24`, the format the API sends and accepts.
  static String toApi(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${_two(date.month)}-${_two(date.day)}';

  /// Parses the API's `YYYY-MM-DD` as a local calendar date.
  static DateTime fromApi(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// `24/10/2026`.
  static String input(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

  /// List header: `Hoje, 24 de outubro`, `Ontem, 23 de outubro`,
  /// `22 de outubro` (with the year when it isn't the current one).
  static String dayHeader(DateTime date, {required DateTime today}) {
    final day = dateOnly(date);
    final now = dateOnly(today);
    var label = '${day.day} de ${_months[day.month - 1]}';
    if (day.year != now.year) label = '$label de ${day.year}';
    if (day == now) return 'Hoje, $label';
    if (day == DateTime(now.year, now.month, now.day - 1)) {
      return 'Ontem, $label';
    }
    return label;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
