enum TransactionType {
  income('income'),
  expense('expense'),

  transfer('transfer'),
  withdrawal('withdrawal');

  const TransactionType(this.apiValue);

  final String apiValue;

  bool get movesGoal => this == transfer || this == withdrawal;

  static TransactionType fromApi(String value) =>
      values.firstWhere((type) => type.apiValue == value);
}
