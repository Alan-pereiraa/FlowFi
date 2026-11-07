import '../../../../shared/utils/money.dart';
import '../../domain/entities/category_draft.dart';

class CategoryDraftDto {
  const CategoryDraftDto(this.data);

  final CategoryDraft data;

  Map<String, dynamic> toJson() => {
    'name': data.name,
    'icon': data.icon,
    'color': data.color,
    'limit_amount': data.limitCents == null
        ? null
        : Money.toApi(data.limitCents!),
  };
}
