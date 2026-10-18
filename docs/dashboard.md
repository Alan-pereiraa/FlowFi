# Dashboard API

Read-only endpoints behind the app's home screen (`app/Domains/Dashboard`). Everything is scoped to the
authenticated user, so there is nothing to pass but filters. All routes are `GET`, live under `/api/v1`
and need `Authorization: Bearer <token>`. They are documented in the Swagger UI (`/api/docs`, tag
**Dashboard**); the schemas are in `app/Http/OpenAPI/DashboardSchemas.php`.

| Route | Returns (`data`) | Query string |
|---|---|---|
| `/dashboard` | every block below in one object | `month` |
| `/dashboard/summary` | income / expense / balance for the month | `month` |
| `/dashboard/spending-by-category` | expenses of the month grouped by category | `month` |
| `/dashboard/upcoming-installments` | list of pending installments, soonest first | `days`, `limit` |
| `/dashboard/recent-transactions` | list of the newest transactions | `limit` |
| `/dashboard/goals` | list of goals with their progress | none |

`GET /dashboard` is the composition of the other five: `summary`, `spending_by_category`,
`upcoming_installments`, `recent_transactions` and `goals` hold exactly what their own route returns under
`data`, plus `unread_notifications` (a count; the list stays at `GET /notifications?status=unread`). Use it
on app launch, and the single routes to refresh one card.

## Query parameters

| Name | Rules | Default |
|---|---|---|
| `month` | `YYYY-MM`, e.g. `2026-09` | current month |
| `days` | integer 1 to 365 | 30 |
| `limit` (upcoming) | integer 1 to 50 | 10 |
| `limit` (recent) | integer 1 to 20 | 5 |

Anything else returns `422` with the usual `errors` object. The overview always uses the defaults of
`days` and `limit`.

## How the numbers are counted

- **Money moves through installments, not transactions.** A transaction counts in the month its installments
  are due: a 3x purchase adds one third to each of three months.
- **`paid` vs `pending`.** Only `paid` installments are real money. `balance` is paid income minus paid
  expense for the month; `projected_balance` is the same with pending ones included.
- **`balance_to_date`** is paid income minus paid expense across all time and ignores `month`.
- **Transfers are neither income nor expense.** A transfer moves money into a goal, so it never touches
  `income`, `expense`, `balance` or `spending_by_category`. The month's transfers are reported on their own
  as `transferred_to_goals`. They still appear in `recent_transactions` (with `category: null` and the
  `goal` they went to).
- **`overdue`** is every pending income or expense installment due before today, from any month, split by
  `income`/`expense`. An installment due today is not overdue.
- **`upcoming-installments`** always includes overdue ones (`overdue: true`), then everything pending up to
  `days` from today.
- **Goals** report the `current_amount` Ledger already maintains (a transfer adds to it, an expense linked
  to the goal takes from it), and `progress_percent` is that over `target_amount`, not capped at 100.
- **Month edges** are inclusive: an installment due on the 1st or on the last day belongs to that month.
- Amounts are decimal strings (`"150.50"`) and can be negative (`"-75.25"`). Percentages are plain numbers.
- Soft-deleted transactions, installments and goals are ignored. A category deleted later still shows up in
  past spending with its old name and color.

### Category limits

`limit_amount` is a monthly cap, as Ledger already enforces it (`CategoryService::ensureInMonthLimit()`).
`limit_used_percent` uses the same sum: expense installments of the category due in the month, paid or not,
over `limit_amount`. It can go past 100.

## Example

`GET /api/v1/dashboard?month=2026-09` (one item kept per list):

```json
{
  "data": {
    "summary": {
      "period": {
        "month": "2026-09",
        "from": "2026-09-01",
        "to": "2026-09-30"
      },
      "income": {
        "paid": "4500.00",
        "pending": "300.00",
        "total": "4800.00"
      },
      "expense": {
        "paid": "480.40",
        "pending": "149.90",
        "total": "630.30"
      },
      "balance": "4019.60",
      "projected_balance": "4169.70",
      "balance_to_date": "4019.60",
      "transferred_to_goals": "250.00",
      "overdue": {
        "expense": {
          "count": 1,
          "amount": "89.90"
        },
        "income": {
          "count": 1,
          "amount": "300.00"
        }
      }
    },
    "spending_by_category": {
      "period": {
        "month": "2026-09",
        "from": "2026-09-01",
        "to": "2026-09-30"
      },
      "categories": [
        {
          "category": {
            "id": 1,
            "name": "Groceries",
            "icon": "shopping_cart",
            "color": "#4CAF50"
          },
          "paid": "470.40",
          "pending": "89.90",
          "total": "560.30",
          "limit_amount": "800.00",
          "limit_used_percent": 70
        }
      ]
    },
    "upcoming_installments": [
      {
        "id": 2,
        "transaction_id": 2,
        "step": 1,
        "installments_count": 1,
        "type": "income",
        "description": null,
        "amount": "300.00",
        "date": "2026-09-10",
        "overdue": true,
        "category": {
          "id": 3,
          "name": "Salary",
          "icon": "payments",
          "color": "#2196F3"
        }
      }
    ],
    "recent_transactions": [
      {
        "id": 7,
        "type": "transfer",
        "description": "Save for the trip",
        "date": "2026-09-14",
        "total_amount": "250.00",
        "installments_count": 1,
        "paid_installments_count": 1,
        "status": "paid",
        "category": null,
        "goal": {
          "id": 1,
          "name": "Trip to Japan",
          "icon": "flight",
          "color": "#FF9800"
        }
      },
      {
        "id": 7,
        "type": "transfer",
        "description": "Save for the trip",
        "date": "2026-09-14",
        "total_amount": "250.00",
        "installments_count": 1,
        "paid_installments_count": 1,
        "status": "paid",
        "category": null,
        "goal": {
          "id": 1,
          "name": "Trip to Japan",
          "icon": "flight",
          "color": "#FF9800"
        }
      }
    ],
    "goals": [
      {
        "id": 1,
        "name": "Trip to Japan",
        "icon": "flight",
        "color": "#FF9800",
        "target_amount": "10000.00",
        "current_amount": "2500.00",
        "progress_percent": 25,
        "expires_at": "2027-03-01"
      }
    ],
    "unread_notifications": 3
  }
}
```

`status` of a recent transaction is `pending` (no installment paid), `partial` (some paid) or `paid` (all paid).
`category` and `goal` can each be `null`.
