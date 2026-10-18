enum TransactionType {
  income('income'),
  expense('expense'),

  /// Money moved into a goal. Not creatable from the transaction form.
  transfer('transfer');

  const TransactionType(this.apiValue);

  final String apiValue;

  static TransactionType fromApi(String value) =>
      values.firstWhere((type) => type.apiValue == value);
}
