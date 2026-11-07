import '../../../../shared/money/money.dart';
import '../../../../shared/utils/money.dart' as cents;
import '../../domain/entities/category.dart';

class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.limitAmount,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) => CategoryDto(
    id: json['id'] as int,
    name: json['name'] as String,
    icon: json['icon'] as String,
    color: json['color'] as String,
    limitAmount: json['limit_amount']?.toString(),
  );

  final int id;
  final String name;
  final String icon;
  final String color;
  final String? limitAmount;

  Category toEntity() => Category(
    id: id,
    name: name,
    icon: icon,
    color: color,
    limitAmount: limitAmount == null ? null : Money.parse(limitAmount!),
    limitCents: cents.Money.parseApi(limitAmount),
  );
}
