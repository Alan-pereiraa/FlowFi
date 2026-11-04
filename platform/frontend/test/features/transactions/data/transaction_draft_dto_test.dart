import 'dart:typed_data';

import 'package:flowfi_app/features/transactions/data/models/transaction_draft_dto.dart';
import 'package:flowfi_app/features/transactions/data/voice/voice_recorder.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flowfi_app/shared/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a goal deposit becomes a transfer draft', () {
    final draft = TransactionDraftDto.fromJson({
      'transcript': 'guardei 200 na viagem',
      'kind': 'transaction',
      'draft': {
        'type': 'transfer',
        'total_amount': '200.00',
        'date': '2026-11-04',
        'description': 'Viagem',
        'category_id': null,
        'goal_id': 7,
        'installments_count': null,
        'period_unit': null,
        'period_interval': null,
      },
    }).toEntity();

    expect(draft.transcript, 'guardei 200 na viagem');
    expect(draft.recurring, isFalse);
    expect(draft.type, TransactionType.transfer);
    expect(draft.amount, const Money(20000));
    expect(draft.date, DateTime(2026, 11, 4));
    expect(draft.goalId, 7);
    expect(draft.missingCount, 0);
  });

  test('a recurring draft reads amount and start date', () {
    final draft = TransactionDraftDto.fromJson({
      'transcript': 'netflix 39,90 todo mês por 12 meses',
      'kind': 'recurring',
      'draft': {
        'type': 'expense',
        'category_id': 3,
        'goal_id': null,
        'description': 'Netflix',
        'amount': '39.90',
        'period_unit': 'month',
        'period_interval': 1,
        'start_date': '2026-11-10',
        'end_date': null,
        'occurrences': 12,
      },
    }).toEntity();

    expect(draft.recurring, isTrue);
    expect(draft.amount, const Money(3990));
    expect(draft.date, DateTime(2026, 11, 10));
    expect(draft.occurrences, 12);
  });

  test('fields the AI could not find are flagged as missing', () {
    final draft = TransactionDraftDto.fromJson({
      'transcript': 'gastei no mercado',
      'kind': 'transaction',
      'draft': {
        'type': 'expense',
        'total_amount': null,
        'date': '2026-11-04',
        'category_id': null,
      },
    }).toEntity();

    expect(draft.missingAmount, isTrue);
    expect(draft.missingCategory, isTrue);
    expect(draft.missingGoal, isFalse);
    expect(draft.missingCount, 2);
  });

  test('WavEncoder writes a 44-byte PCM header', () {
    final wav = WavEncoder.pcm16(Uint8List(32000), sampleRate: 16000);
    final header = ByteData.sublistView(wav, 0, 44);

    expect(wav.length, 44 + 32000);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(header.getUint32(24, Endian.little), 16000);
    expect(header.getUint16(34, Endian.little), 16);
    expect(header.getUint32(40, Endian.little), 32000);
  });
}
