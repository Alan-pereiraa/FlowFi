import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/voice/voice_recorder.dart';
import '../../domain/entities/transaction_draft.dart';

final voiceDraftControllerProvider =
    NotifierProvider.autoDispose<VoiceDraftController, VoiceDraftState>(
      VoiceDraftController.new,
    );

enum VoiceStatus { idle, listening, transcribing, filled, incomplete, failed }

@immutable
class VoiceDraftState {
  const VoiceDraftState({
    this.status = VoiceStatus.idle,
    this.elapsed = Duration.zero,
    this.levels = const [],
    this.draft,
    this.draftVersion = 0,
    this.errorTitle,
    this.errorMessage,
  });

  final VoiceStatus status;
  final Duration elapsed;
  final List<double> levels;
  final TransactionDraft? draft;
  final int draftVersion;
  final String? errorTitle;
  final String? errorMessage;

  bool get busy =>
      status == VoiceStatus.listening || status == VoiceStatus.transcribing;

  VoiceDraftState copyWith({
    VoiceStatus? status,
    Duration? elapsed,
    List<double>? levels,
    TransactionDraft? draft,
    int? draftVersion,
    String? errorTitle,
    String? errorMessage,
  }) {
    return VoiceDraftState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      levels: levels ?? this.levels,
      draft: draft ?? this.draft,
      draftVersion: draftVersion ?? this.draftVersion,
      errorTitle: errorTitle ?? this.errorTitle,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VoiceDraftController extends Notifier<VoiceDraftState> {
  static const maxDuration = Duration(minutes: 1);
  static const _shownLevels = 32;
  static const _minAudioBytes = 44 + 16000;

  Timer? _ticker;
  StreamSubscription<double>? _levels;
  final _stopwatch = Stopwatch();

  late VoiceRecorder _recorder;

  @override
  VoiceDraftState build() {
    _recorder = ref.watch(voiceRecorderProvider);
    ref.onDispose(_stopTracking);
    return const VoiceDraftState();
  }

  Future<void> start() async {
    if (state.busy) return;
    state = VoiceDraftState(
      status: VoiceStatus.listening,
      draft: state.draft,
      draftVersion: state.draftVersion,
    );
    try {
      await _recorder.start();
    } on MicrophoneDeniedException {
      _fail(
        'Microfone bloqueado',
        'Permita o acesso ao microfone para preencher por voz, ou preencha '
            'os campos manualmente.',
      );
      return;
    } on Object {
      _fail(
        'Não foi possível gravar',
        'Tente novamente ou preencha os campos manualmente.',
      );
      return;
    }
    if (!ref.mounted) return;
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final elapsed = _stopwatch.elapsed;
      state = state.copyWith(elapsed: elapsed);
      if (elapsed >= maxDuration) stop();
    });
    _levels = _recorder.levels().listen((level) {
      final levels = [...state.levels, level];
      state = state.copyWith(
        levels: levels.length > _shownLevels
            ? levels.sublist(levels.length - _shownLevels)
            : levels,
      );
    });
  }

  Future<void> stop() async {
    if (state.status != VoiceStatus.listening) return;
    _stopTracking();
    state = state.copyWith(status: VoiceStatus.transcribing);
    try {
      final wav = await _recorder.stop();
      if (wav.length < _minAudioBytes) {
        _fail(
          'Não deu para ouvir',
          'Fale por pelo menos um segundo e tente novamente.',
        );
        return;
      }
      final draft = await ref
          .read(transactionRepositoryProvider)
          .draftFromAudio(wav);
      if (!ref.mounted) return;
      state = VoiceDraftState(
        status: draft.missingCount == 0
            ? VoiceStatus.filled
            : VoiceStatus.incomplete,
        draft: draft,
        draftVersion: state.draftVersion + 1,
      );
    } on RateLimitedFailure {
      _fail(
        'Muitas tentativas',
        'Aguarde um momento antes de gravar de novo, ou preencha os campos '
            'manualmente.',
      );
    } on Object {
      _fail(
        'Não foi possível transcrever',
        'Tente novamente ou preencha os campos manualmente.',
      );
    }
  }

  Future<void> cancel() async {
    if (state.status != VoiceStatus.listening) return;
    _stopTracking();
    state = VoiceDraftState(
      draft: state.draft,
      draftVersion: state.draftVersion,
    );
    try {
      await _recorder.cancel();
    } on Object {
      return;
    }
  }

  void _fail(String title, String message) {
    _stopTracking();
    if (!ref.mounted) return;
    state = VoiceDraftState(
      status: VoiceStatus.failed,
      draft: state.draft,
      draftVersion: state.draftVersion,
      errorTitle: title,
      errorMessage: message,
    );
  }

  void _stopTracking() {
    _ticker?.cancel();
    _ticker = null;
    _levels?.cancel();
    _levels = null;
    _stopwatch.stop();
  }
}
