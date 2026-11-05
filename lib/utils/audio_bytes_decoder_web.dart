import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'wav_decoder.dart';

/// Decodes a browser recording into 16 kHz mono PCM.
///
/// Browsers hand back whatever the recorder produced (commonly WebM/Opus, even
/// when a WAV encoder was requested). Wrapping that bitstream in a WAV header
/// yields noise, so the payload is decoded with the Web Audio API instead and
/// then resampled to 16 kHz with the shared band-limited resampler.
Future<WavDecodeResult> decodeAudioBytes(Uint8List bytes) async {
  if (WavDecoder.isRiffWaveBytes(bytes)) {
    return WavDecoder.decodeWavBytes(bytes);
  }

  final context = web.AudioContext();
  try {
    final payload = Uint8List.fromList(bytes);
    final decoded = await context.decodeAudioData(payload.buffer.toJS).toDart;

    final channelCount = decoded.numberOfChannels;
    final frameCount = decoded.length;
    if (channelCount <= 0 || frameCount <= 0) {
      throw const WavDecodeException('The browser decoded the recording as empty audio.');
    }

    final mono = Float32List(frameCount);
    for (var channel = 0; channel < channelCount; channel++) {
      final samples = decoded.getChannelData(channel).toDart;
      for (var i = 0; i < frameCount; i++) {
        mono[i] += samples[i] / channelCount;
      }
    }

    final sourceRate = decoded.sampleRate.round();
    final pcm = WavDecoder.resampleToTargetRate(mono.toList(), sourceRate);
    if (pcm.isEmpty) {
      throw const WavDecodeException('The browser decoded the recording as empty audio.');
    }

    return WavDecodeResult(
      pcmSamples: pcm,
      sampleRate: WavDecoder.targetSampleRate,
      channels: 1,
      durationSeconds: pcm.length / WavDecoder.targetSampleRate,
    );
  } on WavDecodeException {
    rethrow;
  } catch (error) {
    throw WavDecodeException('Could not decode the recorded audio in the browser: $error');
  } finally {
    try {
      await context.close().toDart;
    } catch (_) {
      // Closing an already-closed context is harmless.
    }
  }
}
