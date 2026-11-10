import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/api_exception.dart';
import 'package:flowfi_app/features/goals/data/datasources/goals_api.dart';
import 'package:flowfi_app/features/goals/data/models/goal_dto.dart';
import 'package:flowfi_app/features/goals/data/models/new_goal_dto.dart';
import 'package:flowfi_app/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:flowfi_app/features/goals/domain/entities/new_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements GoalsApi {}

class _FakeNewGoalDto extends Fake implements NewGoalDto {}

void main() {
  late _MockApi api;
  late GoalRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(_FakeNewGoalDto()));

  setUp(() {
    api = _MockApi();
    repository = GoalRepositoryImpl(api, clock: () => DateTime(2026, 10, 16));
  });

  const created = GoalDto(
    id: 7,
    name: 'Viagem Férias',
    icon: 'flight',
    color: '#00530C',
    targetAmount: '5000.00',
    currentAmount: '0.00',
    expiresAt: '2026-12-31',
  );

  const draft = NewGoal(
    name: 'Viagem Férias',
    icon: 'flight',
    color: '#00530C',
    targetCents: 500000,
  );

  test('GoalDto reads the API decimals and the date', () {
    final goal = GoalDto.fromJson({
      'id': 1,
      'name': 'Fundo',
      'icon': 'savings',
      'color': '#2E7D32',
      'target_amount': '10000.00',
      'current_amount': '1500.00',
      'expires_at': null,
    }).toEntity();

    expect(goal.targetCents, 1000000);
    expect(goal.currentCents, 150000);
    expect(goal.isOpenEnded, isTrue);
    expect(goal.percent, 15);
  });

  test('the create body omits an empty date', () {
    final json = NewGoalDto(draft).toJson();

    expect(json, {
      'name': 'Viagem Férias',
      'icon': 'flight',
      'color': '#00530C',
      'target_amount': '5000.00',
    });
  });

  test('creating a goal returns it as the API saved it', () async {
    when(() => api.createGoal(any())).thenAnswer((_) async => created);

    final result = await repository.create(draft);

    expect(result.id, 7);
    expect(result.currentCents, 0);
  });

  test('a 422 on the goal itself is a ValidationFailure', () {
    when(() => api.createGoal(any())).thenThrow(
      const ApiException(
        statusCode: 422,
        fieldErrors: {
          'name': ['The name has already been taken.'],
        },
      ),
    );

    expect(repository.create(draft), throwsA(isA<ValidationFailure>()));
  });
}
