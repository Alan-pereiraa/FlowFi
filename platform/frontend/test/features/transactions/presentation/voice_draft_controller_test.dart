import 'dart:async';
import 'dart:typed_data';

import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flowfi_app/features/transactions/data/voice/voice_recorder.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_draft.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flowfi_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flowfi_app/features/transactions/presentation/controllers/voice_draft_controller.dart';
import 'package:flowfi_app/shared/money/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactions extends Mock implements TransactionRepository {}

class FakeRecorder implements VoiceRecorder {
  FakeRecorder({this.denied = false, this.audioBytes = 32000});

  final bool denied;
  final int audioBytes;
  bool started = false;
  bool cancelled = false;

  @override
  Future<void> start() async {
    if (denied) throw const MicrophoneDeniedException();
    started = true;
  }

  @override
  Stream<double> levels() => const Stream.empty();

  @override
  Future<Uint8List> stop() async =>
      WavEncoder.pcm16(Uint8List(audioBytes), sampleRate: 16000);

  @override
  Future<void> cancel() async => cancelled = true;

  @override
  Future<void> dispose() async {}
}

const transferDraft = TransactionDraft(
  transcript: 'guardei 200 na viagem',
  recurring: false,
  type: TransactionType.transfer,
  amount: Money(20000),
  goalId: 7,
);

void main() {
  late _MockTransactions transactions;

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  setUp(() => transactions = _MockTransactions());

  ProviderContainer boot(FakeRecorder recorder) {
    final container = ProviderContainer.test(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(transactions),
        voiceRecorderProvider.overrideWithValue(recorder),
      ],
    );
    container.listen(voiceDraftControllerProvider, (_, _) {});
    return container;
  }

  test('records, sends the audio and keeps the draft', () async {
    when(() => transactions.draftFromAudio(any()))
        .thenAnswer((_) async => transferDraft);
    final recorder = FakeRecorder();
    final container = boot(recorder);
    final controller = container.read(voiceDraftControllerProvider.notifier);

    await controller.start();
    expect(recorder.started, isTrue);
    expect(
      container.read(voiceDraftControllerProvider).status,
      VoiceStatus.listening,
    );

    await controller.stop();
    final state = container.read(voiceDraftControllerProvider);

    expect(state.status, VoiceStatus.filled);
    expect(state.draft, transferDraft);
    expect(state.draftVersion, 1);
    final wav =
        verify(() => transactions.draftFromAudio(captureAny())).captured.single
            as Uint8List;
    expect(wav.length, 44 + 32000);
  });

  test('a draft with missing fields is incomplete', () async {
    when(() => transactions.draftFromAudio(any())).thenAnswer(
      (_) async => const TransactionDraft(
        transcript: 'gastei no mercado',
        recurring: false,
        type: TransactionType.expense,
      ),
    );
    final container = boot(FakeRecorder());
    final controller = container.read(voiceDraftControllerProvider.notifier);

    await controller.start();
    await controller.stop();

    expect(
      container.read(voiceDraftControllerProvider).status,
      VoiceStatus.incomplete,
    );
  });

  test('an API failure shows the transcription error', () async {
    when(() => transactions.draftFromAudio(any()))
        .thenThrow(const UnexpectedFailure());
    final container = boot(FakeRecorder());
    final controller = container.read(voiceDraftControllerProvider.notifier);

    await controller.start();
    await controller.stop();
    final state = container.read(voiceDraftControllerProvider);

    expect(state.status, VoiceStatus.failed);
    expect(state.errorTitle, 'Não foi possível transcrever');
    expect(state.draftVersion, 0);
  });

  test('a blocked microphone is reported without calling the API', () async {
    final container = boot(FakeRecorder(denied: true));

    await container.read(voiceDraftControllerProvider.notifier).start();
    final state = container.read(voiceDraftControllerProvider);

    expect(state.status, VoiceStatus.failed);
    expect(state.errorTitle, 'Microfone bloqueado');
    verifyNever(() => transactions.draftFromAudio(any()));
  });

  test('a recording that is too short is not sent', () async {
    final container = boot(FakeRecorder(audioBytes: 1000));
    final controller = container.read(voiceDraftControllerProvider.notifier);

    await controller.start();
    await controller.stop();

    expect(
      container.read(voiceDraftControllerProvider).status,
      VoiceStatus.failed,
    );
    verifyNever(() => transactions.draftFromAudio(any()));
  });

  test('cancel stops listening and discards the audio', () async {
    final recorder = FakeRecorder();
    final container = boot(recorder);
    final controller = container.read(voiceDraftControllerProvider.notifier);

    await controller.start();
    await controller.cancel();

    expect(recorder.cancelled, isTrue);
    expect(
      container.read(voiceDraftControllerProvider).status,
      VoiceStatus.idle,
    );
    verifyNever(() => transactions.draftFromAudio(any()));
  });
}
