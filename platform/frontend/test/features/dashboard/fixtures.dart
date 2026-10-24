Map<String, dynamic> dashboardJson({
  String incomeTotal = '4800.00',
  String expenseTotal = '630.30',
  String projectedBalance = '4169.70',
  List<Map<String, dynamic>>? goals,
  List<Map<String, dynamic>>? recentTransactions,
}) => {
  'summary': {
    'period': {'month': '2026-09', 'from': '2026-09-01', 'to': '2026-09-30'},
    'income': {'paid': '4500.00', 'pending': '300.00', 'total': incomeTotal},
    'expense': {'paid': '480.40', 'pending': '149.90', 'total': expenseTotal},
    'balance': '4019.60',
    'projected_balance': projectedBalance,
    'balance_to_date': '4019.60',
    'transferred_to_goals': '250.00',
    'overdue': {
      'expense': {'count': 1, 'amount': '89.90'},
      'income': {'count': 1, 'amount': '300.00'},
    },
  },
  'spending_by_category': {
    'period': {'month': '2026-09', 'from': '2026-09-01', 'to': '2026-09-30'},
    'categories': <dynamic>[],
  },
  'upcoming_installments': <dynamic>[],
  'recent_transactions':
      recentTransactions ??
      [
        recentTransactionJson(id: 9, type: 'expense'),
        recentTransactionJson(id: 8, type: 'income'),
        recentTransactionJson(id: 7, type: 'transfer'),
        recentTransactionJson(id: 6, type: 'expense'),
        recentTransactionJson(id: 5, type: 'expense'),
      ],
  'goals':
      goals ??
      [
        goalProgressJson(id: 2),
        goalProgressJson(id: 5),
        goalProgressJson(id: 1),
      ],
  'unread_notifications': 3,
};

Map<String, dynamic> recentTransactionJson({
  int id = 7,
  String type = 'expense',
}) => {
  'id': id,
  'type': type,
  'description': type == 'transfer' ? 'Save for the trip' : null,
  'date': '2026-09-14',
  'total_amount': '250.00',
  'installments_count': 1,
  'paid_installments_count': 1,
  'status': 'paid',
  'category': type == 'transfer'
      ? null
      : {'id': 3, 'name': 'Salary', 'icon': 'payments', 'color': '#2196F3'},
  'goal': type == 'transfer'
      ? {'id': 1, 'name': 'Trip to Japan', 'icon': 'flight', 'color': '#FF9800'}
      : null,
};

Map<String, dynamic> goalProgressJson({int id = 1}) => {
  'id': id,
  'name': 'Trip to Japan',
  'icon': 'flight',
  'color': '#FF9800',
  'target_amount': '10000.00',
  'current_amount': '2500.00',
  'progress_percent': 25,
  'expires_at': '2027-03-01',
};
