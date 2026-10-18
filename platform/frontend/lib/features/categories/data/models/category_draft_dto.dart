import '../../../../shared/utils/money.dart';
import '../../domain/entities/category_draft.dart';

/// Body of `POST /categories` and `PATCH /categories/{id}`.
class CategoryDraftDto {
  const CategoryDraftDto(this.data);

  final CategoryDraft data;

  Map<String, dynamic> toJson() => {
    'name': data.name,
    'icon': data.icon,
    'color': data.color,
    // An explicit null is what clears an existing limit on PATCH.
    'limit_amount': data.limitCents == null
        ? null
        : Money.toApi(data.limitCents!),
  };
}
