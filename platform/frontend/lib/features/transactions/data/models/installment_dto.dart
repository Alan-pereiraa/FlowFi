import '../../../../shared/money/money.dart';
import '../../../../shared/utils/dates.dart';
import '../../domain/entities/installment.dart';

/// Mirrors the backend `InstallmentResource`.
class InstallmentDto {
  const InstallmentDto({
    required this.id,
    required this.step,
    required this.amount,
    required this.status,
    required this.date,
    this.paidAt,
  });

  factory InstallmentDto.fromJson(Map<String, dynamic> json) => InstallmentDto(
    id: json['id'] as int,
    step: json['step'] as int,
    amount: json['amount'] as String,
    status: json['status'] as String,
    date: json['date'] as String,
    paidAt: json['paid_at'] as String?,
  );

  final int id;
  final int step;
  final String amount;
  final String status;
  final String date;
  final String? paidAt;

  Installment toEntity() => Installment(
    id: id,
    step: step,
    amount: Money.parse(amount),
    status: status == 'paid'
        ? InstallmentStatus.paid
        : InstallmentStatus.pending,
    date: Dates.fromApi(date),
    paidAt: paidAt == null ? null : DateTime.tryParse(paidAt!),
  );
}
