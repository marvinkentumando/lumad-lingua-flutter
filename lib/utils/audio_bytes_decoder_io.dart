import 'dart:typed_data';

import 'wav_decoder.dart';

/// Decodes an in-memory recording (or reference file) into 16 kHz mono PCM.
///
/// On native platforms recordings are WAV/PCM, so they are parsed directly.
/// Compressed containers are rejected with a [WavDecodeException] instead of
/// being misinterpreted as raw samples.
Future<WavDecodeResult> decodeAudioBytes(Uint8List bytes) async {
  return WavDecoder.decodeAudioBytes(bytes);
}
