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

  static String toApi(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${_two(date.month)}-${_two(date.day)}';

  static DateTime fromApi(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  static String monthYear(DateTime date) =>
      '${_months[date.month - 1]} de ${date.year}';

  static String input(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

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

  static String shortDay(DateTime date, {required DateTime today}) {
    final day = dateOnly(date);
    final now = dateOnly(today);
    if (day == now) return 'Hoje';
    if (day == DateTime(now.year, now.month, now.day - 1)) return 'Ontem';
    final month = _months[day.month - 1];
    final label =
        '${day.day} ${month[0].toUpperCase()}${month.substring(1, 3)}';
    return day.year == now.year ? label : '$label ${day.year}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
