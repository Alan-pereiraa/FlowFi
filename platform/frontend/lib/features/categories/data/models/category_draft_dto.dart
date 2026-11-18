import '../../../../shared/utils/money.dart';
import '../../domain/entities/category_draft.dart';

class CategoryDraftDto {
  const CategoryDraftDto(this.data, {this.includeType = false});

  final CategoryDraft data;
  final bool includeType;

  Map<String, dynamic> toJson() => {
    'name': data.name,
    if (includeType) 'type': data.type.apiValue,
    'icon': data.icon,
    'color': data.color,
    'limit_amount': data.limitCents == null
        ? null
        : Money.toApi(data.limitCents!),
  };
}
