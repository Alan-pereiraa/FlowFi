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

  static String monthYear(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';

  static String full(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

  static String toApi(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static DateTime? parseApi(String? value) {
    if (value == null || value.length < 10) return null;
    return DateTime.tryParse(value.substring(0, 10));
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
