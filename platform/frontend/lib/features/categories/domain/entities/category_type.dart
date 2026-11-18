enum CategoryType {
  expense('expense', 'Saída'),
  income('income', 'Entrada');

  const CategoryType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CategoryType fromApi(String? value) =>
      value == income.apiValue ? income : expense;
}
