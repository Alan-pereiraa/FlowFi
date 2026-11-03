import 'package:flowfi_app/core/clock.dart';
import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:flowfi_app/features/categories/domain/entities/category.dart';
import 'package:flowfi_app/features/categories/domain/repositories/category_repository.dart';
import 'package:flowfi_app/features/categories/presentation/controllers/categories_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements CategoryRepository {}

const _market = Category(
  id: 1,
  name: 'Mercado',
  icon: 'shopping_cart',
  color: '#E53935',
  limitCents: 65000,
);
const _fun = Category(
  id: 2,
  name: 'Lazer',
  icon: 'local_offer',
  color: '#2E7D32',
  limitCents: 20000,
);

void main() {
  late _MockRepository repository;
  final now = DateTime(2026, 10, 30);

  setUpAll(() => registerFallbackValue(DateTime(2000)));

  setUp(() {
    repository = _MockRepository();
    when(() => repository.list()).thenAnswer((_) async => [_market, _fun]);
  });

  Future<ProviderContainer> boot() async {
    final container = ProviderContainer.test(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    container.listen(categoriesListControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container;
  }

  test(
    'loads this month spending; categories without expense are zero',
    () async {
      when(() => repository.spentInMonth(now))
          .thenAnswer((_) async => {1: 52000});
      final container = await boot();
      final state = container.read(categoriesListControllerProvider);

      expect(state.categories, [_market, _fun]);
      expect(state.spentOf(1), 52000);
      expect(state.spentOf(2), 0);
    },
  );

  test('a spending failure still shows the list, without amounts', () async {
    when(() => repository.spentInMonth(any()))
        .thenThrow(const NetworkFailure());
    final container = await boot();
    final state = container.read(categoriesListControllerProvider);

    expect(state.loaded, isTrue);
    expect(state.categories, [_market, _fun]);
    expect(state.spentOf(1), isNull);
  });
}
