// Samples shaped like the backend Ledger resources.

/// Shaped like the backend `TransactionResource` with installments loaded.
Map<String, dynamic> transactionJson({
  int id = 12,
  String type = 'expense',
  String date = '2026-10-24',
  List<Map<String, dynamic>>? installments,
}) => {
  'id': id,
  'category_id': 3,
  'goal_id': null,
  'type': type,
  'description': 'Almoço',
  'date': date,
  'total_amount': '100.01',
  'installments_count': 2,
  'schedule_type': 'periodic',
  'period_unit': 'month',
  'period_interval': 1,
  'installments':
      installments ??
      [
        {
          'id': 30,
          'step': 1,
          'amount': '50.01',
          'status': 'paid',
          'date': '2026-10-24',
          'paid_at': '2026-10-24T13:00:00.000000Z',
          'created_at': '2026-10-24T13:00:00.000000Z',
          'updated_at': '2026-10-24T13:00:00.000000Z',
        },
        {
          'id': 31,
          'step': 2,
          'amount': '50.00',
          'status': 'pending',
          'date': '2026-11-24',
          'paid_at': null,
          'created_at': '2026-10-24T13:00:00.000000Z',
          'updated_at': '2026-10-24T13:00:00.000000Z',
        },
      ],
  'created_at': '2026-10-24T13:00:00.000000Z',
  'updated_at': '2026-10-24T13:00:00.000000Z',
};

Map<String, dynamic> categoryJson({int id = 3, String? limit}) => {
  'id': id,
  'name': 'Alimentação',
  'icon': 'restaurant',
  'color': '#43A94D',
  'limit_amount': limit,
  'created_at': '2026-10-01T10:00:00.000000Z',
  'updated_at': '2026-10-01T10:00:00.000000Z',
};
