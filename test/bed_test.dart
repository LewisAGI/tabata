import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bed.wav is silent pcm of the same format', () async {
    final data = await rootBundle.load('assets/audio/bed.wav');
    final wav = _Wav.parse(data);
    expect(wav.audioFormat, 1);
    expect(wav.channels, 1);
    expect(wav.sampleRate, 44100);
    expect(wav.bitsPerSample, 16);
    expect(wav.samples, isNotEmpty);
    expect(wav.peak, 0);
  });
}

class _Wav {
  _Wav({
    required this.audioFormat,
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.samples,
  });

  final int audioFormat;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final List<int> samples;

  int get peak {
    var peak = 0;
    for (final sample in samples) {
      final abs = sample.abs();
      if (abs > peak) {
        peak = abs;
      }
    }
    return peak;
  }

  static _Wav parse(ByteData data) {
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    int? audioFormat;
    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    List<int>? samples;
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final size = ByteData.sublistView(
        bytes,
        offset + 4,
        offset + 8,
      ).getUint32(0, Endian.little);
      final start = offset + 8;
      final end = start + size;
      expect(end, lessThanOrEqualTo(bytes.length));
      if (id == 'fmt ') {
        final fmt = ByteData.sublistView(bytes, start, end);
        audioFormat = fmt.getUint16(0, Endian.little);
        channels = fmt.getUint16(2, Endian.little);
        sampleRate = fmt.getUint32(4, Endian.little);
        bitsPerSample = fmt.getUint16(14, Endian.little);
      } else if (id == 'data') {
        final pcm = ByteData.sublistView(bytes, start, end);
        samples = [
          for (var i = 0; i + 1 < pcm.lengthInBytes; i += 2)
            pcm.getInt16(i, Endian.little),
        ];
      }
      offset = end + (size.isOdd ? 1 : 0);
    }
    return _Wav(
      audioFormat: audioFormat!,
      channels: channels!,
      sampleRate: sampleRate!,
      bitsPerSample: bitsPerSample!,
      samples: samples!,
    );
  }
}
