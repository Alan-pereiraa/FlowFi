enum TransactionType {
  income('income'),
  expense('expense'),

  /// Money moved into a goal. Not creatable from the transaction form.
  transfer('transfer'),
  withdrawal('withdrawal');

  const TransactionType(this.apiValue);

  final String apiValue;

  bool get movesGoal => this == transfer || this == withdrawal;

  static TransactionType fromApi(String value) =>
      values.firstWhere((type) => type.apiValue == value);
}
