import 'package:material_ui/material_ui.dart';

import '../../../../shared/utils/dates.dart';
import '../../domain/entities/installment.dart';

class InstallmentsSection extends StatelessWidget {
  const InstallmentsSection({
    super.key,
    required this.installments,
    required this.busy,
    required this.updatingId,
    required this.onToggle,
  });

  final List<Installment> installments;
  final bool busy;
  final int? updatingId;
  final ValueChanged<Installment> onToggle;

  String _status(Installment installment) {
    if (installment.isPaid) return 'Paga';
    return 'Pendente';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          installments.length > 1 ? 'Parcelas' : 'Pagamento',
          style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        for (final installment in installments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${installment.step}/${installments.length} • '
                        '${installment.amount.format()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        '${Dates.input(installment.date)} • '
                        '${_status(installment)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (installment.isPaid)
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(96, 40),
                    ),
                    onPressed: busy ? null : () => onToggle(installment),
                    child: Text(
                      updatingId == installment.id ? 'Aguarde...' : 'Desfazer',
                    ),
                  )
                else
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 40),
                    ),
                    onPressed: busy ? null : () => onToggle(installment),
                    child: Text(
                      updatingId == installment.id ? 'Aguarde...' : 'Pagar',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
