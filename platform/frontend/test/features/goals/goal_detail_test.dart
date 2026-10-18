import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/api_exception.dart';
import 'package:flowfi_app/features/goals/data/datasources/goals_api.dart';
import 'package:flowfi_app/features/goals/data/models/goal_dto.dart';
import 'package:flowfi_app/features/goals/data/models/goal_update_dto.dart';
import 'package:flowfi_app/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:flowfi_app/features/goals/domain/entities/goal.dart';
import 'package:flowfi_app/features/goals/domain/entities/goal_update.dart';
import 'package:flowfi_app/shared/errors/ledger_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements GoalsApi {}

class _FakeUpdateDto extends Fake implements GoalUpdateDto {}

void main() {
  late _MockApi api;
  late GoalRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(_FakeUpdateDto()));

  setUp(() {
    api = _MockApi();
    repository = GoalRepositoryImpl(api, clock: () => DateTime(2026, 10, 16));
  });

  const goal = Goal(
    id: 7,
    name: 'Viagem',
    icon: 'flight',
    color: '#00530C',
    targetCents: 500000,
    currentCents: 100000,
  );

  const refreshed = GoalDto(
    id: 7,
    name: 'Viagem',
    icon: 'flight',
    color: '#00530C',
    targetAmount: '5000.00',
    currentAmount: '1250.00',
  );

  When<Future<void>> stubDeposit() => when(
    () => api.depositToGoal(
      goalId: any(named: 'goalId'),
      amount: any(named: 'amount'),
      date: any(named: 'date'),
      description: any(named: 'description'),
    ),
  );

  test('the update body sends an explicit null to clear the deadline', () {
    final json = GoalUpdateDto(
      const GoalUpdate(
        name: 'Viagem',
        icon: 'flight',
        color: '#00530C',
        targetCents: 500000,
      ),
    ).toJson();

    expect(json.containsKey('expires_at'), isTrue);
    expect(json['expires_at'], isNull);
    expect(json['target_amount'], '5000.00');
  });

  test('the update body formats the deadline', () {
    final json = GoalUpdateDto(
      GoalUpdate(
        name: 'Viagem',
        icon: 'flight',
        color: '#00530C',
        targetCents: 500000,
        expiresAt: DateTime(2027, 3, 5),
      ),
    ).toJson();

    expect(json['expires_at'], '2027-03-05');
  });

  test('a deposit is a transfer, then the goal is read back', () async {
    stubDeposit().thenAnswer((_) async {});
    when(() => api.showGoal(7)).thenAnswer((_) async => refreshed);

    final result = await repository.deposit(goal, 25000);

    verify(
      () => api.depositToGoal(
        goalId: 7,
        amount: '250.00',
        date: '2026-10-16',
        description: GoalRepositoryImpl.depositDescription,
      ),
    ).called(1);
    expect(result.currentCents, 125000);
  });

  test('if only the read-back fails the balance is added locally', () async {
    stubDeposit().thenAnswer((_) async {});
    when(() => api.showGoal(7)).thenThrow(const ApiException(statusCode: 500));

    final result = await repository.deposit(goal, 25000);

    expect(result.currentCents, 125000);
  });

  test('an expired session on the read-back is not swallowed', () {
    stubDeposit().thenAnswer((_) async {});
    when(() => api.showGoal(7)).thenThrow(const ApiException(statusCode: 401));

    expect(repository.deposit(goal, 25000), throwsA(isA<UnauthorizedFailure>()));
  });

  test('a rejected deposit is a ValidationFailure', () {
    stubDeposit().thenThrow(const ApiException(statusCode: 422));

    expect(repository.deposit(goal, 25000), throwsA(isA<ValidationFailure>()));
  });

  test('deleting a goal with deposits explains why', () {
    const failure = ValidationFailure(
      message: 'The goal has transactions.',
      fieldErrors: {
        'goal': ['The goal has transactions.'],
      },
    );

    expect(
      LedgerErrorMessages.goalDelete(failure),
      'Não é possível excluir uma meta que já tem valores adicionados.',
    );
  });

  test('a rejected deposit has its own message', () {
    expect(
      LedgerErrorMessages.goalDeposit(const ValidationFailure(message: 'x')),
      contains('Não foi possível adicionar'),
    );
  });
}
