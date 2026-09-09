# FlowFi — Data Model (ERD)

Target schema for the `Ledger` domain slice (plus notifications). Implemented
so far: the `Identity` slice (`users`, `otp_codes`, `personal_access_tokens`)
and, from `Ledger`, `goals` and `categories`. Each "Status" line below records
how a drawn entity was realized.

`ACCOUNT` is the evolution of the current `User` model
(`packages/backend/app/Domains/Identity/Models/User.php`) — `name` split into
`firstName`/`lastName`, plus `phoneNumber`.

Status: `ACCOUNT` is realized on the existing `users` table (no rename) as
`first_name`, `last_name`, `phone_number` and `deleted_at` (`SoftDeletes`).

Status: `GOAL` is realized as `goals` (`app/Domains/Ledger/Models/Goal.php`):
`accountId` → `user_id` (FK to `users.id`, indexed), `targetAmount` → integer
cents in `target_amount` (exposed as a decimal string through the `Money`
cast), `expiresDate` → nullable `date expires_at`, `color` → `#RRGGBB` string,
`deleteAt` → `deleted_at`.

Status: `CATEGORY` is realized as `categories`
(`app/Domains/Ledger/Models/Category.php`): `accountId` → `user_id` (FK to
`users.id`, indexed), `color` → `#RRGGBB` string (not `INT`), `deleteAt` →
`deleted_at`, plus one column not in the original drawing, `limitAmount` →
nullable integer cents in `limit_amount` behind the `Money` cast (the maximum
a user wants to allot to the category; null = no cap). `name` is unique per
user among live rows, enforced in validation only (no DB unique index, so a
soft-deleted name can be reused).

## Cardinalities

Source diagram uses min-max pairs; the pair sits on the side it counts.

| Relationship | Reading |
|---|---|
| ACCOUNT → NOTIFICATION | 1 account has 0..n notifications |
| ACCOUNT → CATEGORY | 1 account has 0..n categories |
| ACCOUNT → GOAL | 1 account has 0..n goals |
| ACCOUNT → TRANSACTION | 1 account has 0..n transactions |
| CATEGORY → TRANSACTION | 1 category classifies 0..n transactions |
| GOAL → TRANSACTION | 1 goal is funded by 0..n transactions |
| TRANSACTION → INSTALLMENT | 1 transaction splits into 1..n installments |

The `TRANSACTION → INSTALLMENT` pair is `(1,1) (1,n)`; the drawing tool used for
the original diagram could not render `(1,n)` and showed `(0,n)` instead.

## Diagram

```mermaid
erDiagram
    ACCOUNT ||--o{ NOTIFICATION : "receives"
    ACCOUNT ||--o{ CATEGORY     : "owns"
    ACCOUNT ||--o{ GOAL         : "sets"
    ACCOUNT ||--o{ TRANSACTION  : "records"
    CATEGORY ||--o{ TRANSACTION : "classifies"
    GOAL     ||--o{ TRANSACTION : "funded by"
    TRANSACTION ||--|{ INSTALLMENT : "split into"

    ACCOUNT {
        int      ID          PK
        varchar  firstName
        varchar  lastName
        varchar  phoneNumber
        varchar  email
        datetime createdAt
        datetime updatedAt
        datetime deleteAt
    }

    NOTIFICATION {
        int      ID        PK
        int      accountId FK
        enum     type
        varchar  subject
        int      subjectId
        datetime readAt
        datetime createdAt
        datetime updatedAt
        datetime deleteAt
    }

    CATEGORY {
        int      ID          PK
        int      accountId   FK
        varchar  name
        varchar  icon
        int      color
        float    limitAmount
        datetime createdAt
        datetime updatedAt
        datetime deleteAt
    }

    GOAL {
        int      ID           PK
        varchar  name
        varchar  icon
        varchar  color
        float    targetAmount
        int      accountId    FK
        int      expiresDate
        datetime createdAt
        datetime updatedAt
        datetime deleteAt
    }

    TRANSACTION {
        int      ID                 PK
        int      accountId          FK
        int      categoryId         FK
        int      goalId             FK
        float    totalAmount
        enum     type
        date     date
        varchar  description
        varchar  period
        int      installmentNumbers
        datetime createdAt
        datetime updatedAt
        datetime deleteAt
    }

    INSTALLMENT {
        int      ID            PK
        int      transactionId FK
        float    amount
        int      step
        enum     status
        date     date
        datetime paidAt
        datetime createdAt
        datetime updatedAt
        datetime deleteAt
    }
```

## Ownership notes

- `ACCOUNT` is the aggregate root. Every entity except `INSTALLMENT` carries
  `accountId` — that column is the tenant-isolation key for every query.
- `INSTALLMENT` reaches the account only through `TRANSACTION`: the payment
  schedule is transaction-local by design.
- `NOTIFICATION.subject` + `subjectId` is a polymorphic pointer (Laravel
  `morphTo`, i.e. `subject_type` / `subject_id`) — no FK constraint.
- `TRANSACTION` is the join point between classification (category),
  allocation (goal) and schedule (installments).
- Auth and tokens stay outside this model — Sanctum and the `Identity` slice.

## Open points

- `deleteAt` should be `deletedAt` (`deleted_at`) for Laravel `SoftDeletes`.
  Done for `ACCOUNT` (`users.deleted_at`), `GOAL` (`goals.deleted_at`) and
  `CATEGORY` (`categories.deleted_at`); still applies to the other entities.
- `GOAL.expiresDate` is typed `INT` but named as a date. Resolved: nullable
  `date expires_at`.
- `color` is `INT` on `CATEGORY` and `VARCHAR` on `GOAL`. Resolved for both as
  a `#RRGGBB` string; they share the `AppearanceService`. The diagram keeps
  the original `int` on `CATEGORY` for fidelity to the source drawing.
- Money columns (`GOAL.targetAmount`, `CATEGORY.limitAmount`,
  `TRANSACTION.totalAmount`, `INSTALLMENT.amount`) are drawn as `FLOAT`.
  Resolved for `GOAL` and `CATEGORY` as integer cents behind the shared
  `Money` cast; the other two should follow.
- `CATEGORY.limitAmount` has no period attached (per month? total?). Decide
  when `TRANSACTION` lands and spend can actually be compared against it.
- `TRANSACTION.goalId` is drawn mandatory `(1,1)`; most transactions have no
  goal, so it likely wants to be nullable `(0,1)`.
- `TRANSACTION.installmentNumbers` duplicates `COUNT(INSTALLMENT)`.
- `TRANSACTION.period` is `VARCHAR` while `type` is `ENUM`; period looks
  enum-shaped too.
- `ACCOUNT` carries no `password` / `email_verified_at`. Resolved: `ACCOUNT`
  stayed on `users`; `password` was dropped (auth is OTP-only, codes live in
  `otp_codes`) and `email_verified_at` is kept and set when a code is verified.
