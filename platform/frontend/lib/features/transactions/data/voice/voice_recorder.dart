import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

final voiceRecorderProvider = Provider.autoDispose<VoiceRecorder>((ref) {
  final recorder = RecordVoiceRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

class MicrophoneDeniedException implements Exception {
  const MicrophoneDeniedException();
}

abstract interface class VoiceRecorder {
  Future<void> start();

  Stream<double> levels();

  Future<Uint8List> stop();

  Future<void> cancel();

  Future<void> dispose();
}

class RecordVoiceRecorder implements VoiceRecorder {
  RecordVoiceRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  static const sampleRate = 16000;

  final AudioRecorder _recorder;
  final _chunks = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _subscription;

  @override
  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      throw const MicrophoneDeniedException();
    }
    _chunks.clear();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ),
    );
    _subscription = stream.listen(_chunks.add);
  }

  @override
  Stream<double> levels() => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 120))
      .map((a) => ((a.current + 50) / 50).clamp(0.0, 1.0).toDouble());

  @override
  Future<Uint8List> stop() async {
    await _recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
    return WavEncoder.pcm16(_chunks.takeBytes(), sampleRate: sampleRate);
  }

  @override
  Future<void> cancel() async {
    await _subscription?.cancel();
    _subscription = null;
    _chunks.clear();
    await _recorder.cancel();
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _recorder.dispose();
  }
}

abstract final class WavEncoder {
  static Uint8List pcm16(
    Uint8List pcm, {
    required int sampleRate,
    int channels = 1,
  }) {
    final byteRate = sampleRate * channels * 2;
    final header = ByteData(44)
      ..setUint32(0, 0x52494646)
      ..setUint32(4, 36 + pcm.length, Endian.little)
      ..setUint32(8, 0x57415645)
      ..setUint32(12, 0x666d7420)
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, channels, Endian.little)
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, byteRate, Endian.little)
      ..setUint16(32, channels * 2, Endian.little)
      ..setUint16(34, 16, Endian.little)
      ..setUint32(36, 0x64617461)
      ..setUint32(40, pcm.length, Endian.little);
    return (BytesBuilder(copy: false)
          ..add(header.buffer.asUint8List())
          ..add(pcm))
        .takeBytes();
  }
}
