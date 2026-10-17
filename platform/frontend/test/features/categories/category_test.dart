import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/api_exception.dart';
import 'package:flowfi_app/features/categories/data/datasources/categories_api.dart';
import 'package:flowfi_app/features/categories/data/models/category_draft_dto.dart';
import 'package:flowfi_app/features/categories/data/models/category_dto.dart';
import 'package:flowfi_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:flowfi_app/features/categories/domain/entities/category.dart';
import 'package:flowfi_app/features/categories/domain/entities/category_draft.dart';
import 'package:flowfi_app/shared/errors/ledger_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements CategoriesApi {}

class _FakeDraftDto extends Fake implements CategoryDraftDto {}

const transporte = Category(
  id: 3,
  name: 'Transporte',
  icon: 'directions_car',
  color: '#42A5F5',
  limitCents: 20000,
);

void main() {
  group('Category limit math (the dashboard mock-up)', () {
    test('R\$ 180,50 of R\$ 200,00 is 90% and near the limit', () {
      expect(transporte.usedPercent(18050), 90);
      expect(transporte.isNearLimit(18050), isTrue);
    });

    test('R\$ 150 of R\$ 300 is 50% and not near the limit', () {
      const alimentacao = Category(
        id: 1,
        name: 'Alimentação',
        icon: 'restaurant',
        color: '#FF7043',
        limitCents: 30000,
      );
      expect(alimentacao.usedPercent(15000), 50);
      expect(alimentacao.isNearLimit(15000), isFalse);
    });

    test('80% is already "near", the backend notifies at the same point', () {
      expect(transporte.isNearLimit(16000), isTrue);
      expect(transporte.isNearLimit(15999), isFalse);
    });

    test('a category without limit has no percentage and is never near', () {
      const outros = Category(
        id: 4,
        name: 'Outros',
        icon: 'local_offer',
        color: '#78909C',
      );
      expect(outros.hasLimit, isFalse);
      expect(outros.usedPercent(5000), isNull);
      expect(outros.isNearLimit(999999), isFalse);
    });
  });

  group('DTOs', () {
    test('reads limit_amount as cents, and null as no limit', () {
      final withLimit = CategoryDto.fromJson({
        'id': 3,
        'name': 'Transporte',
        'icon': 'directions_car',
        'color': '#42A5F5',
        'limit_amount': '200.00',
      }).toEntity();
      final without = CategoryDto.fromJson({
        'id': 4,
        'name': 'Outros',
        'icon': 'local_offer',
        'color': '#78909C',
        'limit_amount': null,
      }).toEntity();

      expect(withLimit.limitCents, 20000);
      expect(without.limitCents, isNull);
    });

    test('the body sends limit_amount as a decimal string', () {
      final json = CategoryDraftDto(
        const CategoryDraft(
          name: 'Transporte',
          icon: 'directions_car',
          color: '#42A5F5',
          limitCents: 20000,
        ),
      ).toJson();

      expect(json['limit_amount'], '200.00');
    });

    test('removing the limit sends an explicit null, which clears it', () {
      final json = CategoryDraftDto(
        const CategoryDraft(
          name: 'Transporte',
          icon: 'directions_car',
          color: '#42A5F5',
        ),
      ).toJson();

      expect(json.containsKey('limit_amount'), isTrue);
      expect(json['limit_amount'], isNull);
    });
  });

  group('CategoryRepositoryImpl', () {
    late _MockApi api;
    late CategoryRepositoryImpl repository;

    setUpAll(() => registerFallbackValue(_FakeDraftDto()));

    setUp(() {
      api = _MockApi();
      repository = CategoryRepositoryImpl(api);
    });

    test('list maps the DTOs to entities', () async {
      when(() => api.listCategories()).thenAnswer(
        (_) async => const [
          CategoryDto(
            id: 3,
            name: 'Transporte',
            icon: 'directions_car',
            color: '#42A5F5',
            limitAmount: '200.00',
          ),
        ],
      );

      expect(await repository.list(), [transporte]);
    });

    test('a duplicate name comes back as a ValidationFailure', () {
      when(() => api.createCategory(any())).thenThrow(
        const ApiException(
          statusCode: 422,
          fieldErrors: {
            'name': ['The name has already been taken.'],
          },
        ),
      );

      expect(
        repository.create(
          const CategoryDraft(name: 'Lazer', icon: 'movie', color: '#FFCA28'),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('a missing category is a NotFoundFailure', () {
      when(() => api.deleteCategory(9)).thenThrow(
        const ApiException(statusCode: 404),
      );

      expect(repository.remove(9), throwsA(isA<NotFoundFailure>()));
    });

    test('offline is a NetworkFailure', () {
      when(() => api.listCategories()).thenThrow(const ApiException());

      expect(repository.list(), throwsA(isA<NetworkFailure>()));
    });
  });

  group('LedgerErrorMessages', () {
    ValidationFailure failure(String field, String message) =>
        ValidationFailure(
          fieldErrors: {
            field: [message],
          },
        );

    test('a duplicate name reads as a sentence the user can act on', () {
      expect(
        LedgerErrorMessages.categoryField(
          failure('name', 'The name has already been taken.'),
          'name',
        ),
        'Você já tem uma categoria com esse nome.',
      );
      expect(
        LedgerErrorMessages.goalField(
          failure('name', 'The name has already been taken.'),
          'name',
        ),
        'Você já tem uma meta com esse nome.',
      );
    });

    test('never shows raw backend English', () {
      final message = LedgerErrorMessages.categoryField(
        failure('limit_amount', 'The limit amount field must be a number.'),
        'limit_amount',
      );
      expect(message, 'Limite inválido.');
    });

    test('a field with no error is null', () {
      expect(
        LedgerErrorMessages.goalField(
          failure('name', 'The name field is required.'),
          'target_amount',
        ),
        isNull,
      );
    });
  });
}
