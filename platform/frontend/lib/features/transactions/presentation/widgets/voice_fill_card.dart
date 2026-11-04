import 'package:material_ui/material_ui.dart';

import '../../../../shared/theme/app_colors.dart';
import '../controllers/voice_draft_controller.dart';

class VoiceFillCard extends StatelessWidget {
  const VoiceFillCard({
    super.key,
    required this.state,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
  });

  final VoiceDraftState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = theme.extension<AppColors>()!.success;
    final listening = state.status == VoiceStatus.listening;

    final (
      Widget leading,
      String title,
      String subtitle,
    ) = switch (state.status) {
      VoiceStatus.idle => (
        _RoundButton(
          icon: Icons.mic,
          tooltip: 'Gravar',
          background: scheme.primary,
          foreground: scheme.onPrimary,
          onPressed: onStart,
        ),
        'Preencher por voz',
        'Toque e fale o valor, o que foi e a categoria.',
      ),
      VoiceStatus.listening => (
        _RoundButton(
          icon: Icons.stop,
          tooltip: 'Parar e preencher',
          background: scheme.error,
          foreground: scheme.onError,
          onPressed: onStop,
        ),
        'Ouvindo...',
        '${_clock(state.elapsed)} de '
            '${_clock(VoiceDraftController.maxDuration)} · Toque para parar',
      ),
      VoiceStatus.transcribing => (
        const SizedBox.square(
          dimension: 44,
          child: Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
        'Transcrevendo sua mensagem...',
        'Os campos serão preenchidos em seguida.',
      ),
      VoiceStatus.filled => (
        _StatusIcon(icon: Icons.check_circle, color: success),
        'Campos preenchidos',
        'Confira os dados antes de salvar.',
      ),
      VoiceStatus.incomplete => (
        _StatusIcon(icon: Icons.error_outline, color: scheme.error),
        'Faltam informações',
        state.draft!.missingCount == 1
            ? 'Confira o campo destacado abaixo.'
            : 'Confira os ${state.draft!.missingCount} campos destacados '
                  'abaixo.',
      ),
      VoiceStatus.failed => (
        _StatusIcon(icon: Icons.error_outline, color: scheme.error),
        state.errorTitle ?? 'Não foi possível transcrever',
        state.errorMessage ??
            'Tente novamente ou preencha os campos manualmente.',
      ),
    };

    final borderColor = switch (state.status) {
      VoiceStatus.listening => scheme.error,
      VoiceStatus.filled => success,
      VoiceStatus.incomplete ||
      VoiceStatus.failed => scheme.error.withValues(alpha: 0.5),
      _ => scheme.outlineVariant,
    };

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: state.status == VoiceStatus.incomplete
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (listening) ...[
              const SizedBox(height: 12),
              _Waveform(levels: state.levels, color: scheme.error),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
            if (state.status case VoiceStatus.filled || VoiceStatus.incomplete)
              if (state.draft!.transcript.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Você disse',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.draft!.transcript,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            if (state.status
                case VoiceStatus.filled ||
                    VoiceStatus.incomplete ||
                    VoiceStatus.failed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onStart,
                  icon: Icon(
                    state.status == VoiceStatus.failed
                        ? Icons.refresh
                        : Icons.mic,
                    size: 18,
                  ),
                  label: Text(
                    state.status == VoiceStatus.failed
                        ? 'Tentar novamente'
                        : 'Gravar novamente',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _clock(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 24,
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        fixedSize: const Size.square(44),
      ),
      icon: Icon(icon),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: color.withValues(alpha: 0.12),
      foregroundColor: color,
      child: Icon(icon),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  static const _bars = 32;

  @override
  Widget build(BuildContext context) {
    final padded = [
      for (var i = 0; i < _bars - levels.length; i++) 0.0,
      ...levels,
    ];
    return ExcludeSemantics(
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final level in padded)
              Container(
                width: 3,
                height: 4 + 28 * level,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.35 + 0.65 * level),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
