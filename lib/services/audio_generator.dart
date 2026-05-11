import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;

/// Parameters for generating binaural beats in isolate
class BinauralParams {
  final double leftFrequency;
  final double rightFrequency;
  final double volume;
  final int sampleRate;
  final int durationSeconds;

  BinauralParams({
    required this.leftFrequency,
    required this.rightFrequency,
    this.volume = 0.5,
    this.sampleRate = 44100,
    int targetDurationSeconds = 30,
  }) : durationSeconds = _calculateSeamlessLoopDuration(
         leftFrequency, rightFrequency, targetDurationSeconds);

  /// Calculate a duration where both frequencies complete whole cycles
  /// This ensures the sine waves align at the loop boundary for seamless looping
  static int _calculateSeamlessLoopDuration(
    double leftFreq, double rightFreq, int targetDuration) {
    // Search for a duration near target where both frequencies complete whole cycles
    int bestDuration = targetDuration;
    double minError = double.infinity;

    for (int d = targetDuration - 10; d <= targetDuration + 10; d++) {
      if (d <= 0) continue;

      double leftCycles = leftFreq * d;
      double rightCycles = rightFreq * d;

      // Calculate how far each is from completing whole cycles
      double leftError = (leftCycles - leftCycles.roundToDouble()).abs();
      double rightError = (rightCycles - rightCycles.roundToDouble()).abs();
      double totalError = leftError + rightError;

      if (totalError < minError) {
        minError = totalError;
        bestDuration = d;
      }

      // Perfect alignment found
      if (totalError < 0.0001) break;
    }

    return bestDuration;
  }
}

/// Generate binaural beat audio data in a background isolate
Uint8List _generateBinauralBeatIsolate(BinauralParams params) {
  final numSamples = params.sampleRate * params.durationSeconds;
  const numChannels = 2; // Stereo
  const bitsPerSample = 16;
  final byteRate = params.sampleRate * numChannels * (bitsPerSample ~/ 8);
  const blockAlign = numChannels * (bitsPerSample ~/ 8);
  final dataSize = numSamples * numChannels * (bitsPerSample ~/ 8);
  final fileSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);
  int offset = 0;

  // RIFF header
  buffer.setUint8(offset++, 0x52); // 'R'
  buffer.setUint8(offset++, 0x49); // 'I'
  buffer.setUint8(offset++, 0x46); // 'F'
  buffer.setUint8(offset++, 0x46); // 'F'
  buffer.setUint32(offset, fileSize, Endian.little);
  offset += 4;
  buffer.setUint8(offset++, 0x57); // 'W'
  buffer.setUint8(offset++, 0x41); // 'A'
  buffer.setUint8(offset++, 0x56); // 'V'
  buffer.setUint8(offset++, 0x45); // 'E'

  // fmt chunk
  buffer.setUint8(offset++, 0x66); // 'f'
  buffer.setUint8(offset++, 0x6D); // 'm'
  buffer.setUint8(offset++, 0x74); // 't'
  buffer.setUint8(offset++, 0x20); // ' '
  buffer.setUint32(offset, 16, Endian.little); // Subchunk1Size
  offset += 4;
  buffer.setUint16(offset, 1, Endian.little); // AudioFormat (PCM)
  offset += 2;
  buffer.setUint16(offset, numChannels, Endian.little);
  offset += 2;
  buffer.setUint32(offset, params.sampleRate, Endian.little);
  offset += 4;
  buffer.setUint32(offset, byteRate, Endian.little);
  offset += 4;
  buffer.setUint16(offset, blockAlign, Endian.little);
  offset += 2;
  buffer.setUint16(offset, bitsPerSample, Endian.little);
  offset += 2;

  // data chunk
  buffer.setUint8(offset++, 0x64); // 'd'
  buffer.setUint8(offset++, 0x61); // 'a'
  buffer.setUint8(offset++, 0x74); // 't'
  buffer.setUint8(offset++, 0x61); // 'a'
  buffer.setUint32(offset, dataSize, Endian.little);
  offset += 4;

  // Generate audio samples
  // Note: Duration is calculated to ensure both frequencies complete whole cycles,
  // so the sine waves align perfectly at the loop boundary (no fade needed)
  final maxAmplitude = (32767 * params.volume).toInt();
  final twoPi = 2 * pi;

  for (int i = 0; i < numSamples; i++) {
    final t = i / params.sampleRate;

    // Left channel - base frequency
    final leftSample = (sin(twoPi * params.leftFrequency * t) * maxAmplitude).toInt();
    buffer.setInt16(offset, leftSample, Endian.little);
    offset += 2;

    // Right channel - base frequency + beat frequency
    final rightSample = (sin(twoPi * params.rightFrequency * t) * maxAmplitude).toInt();
    buffer.setInt16(offset, rightSample, Endian.little);
    offset += 2;
  }

  return buffer.buffer.asUint8List();
}

/// Service for managing binaural beat playback
class BinauralBeatService {
  final AudioPlayer _player = AudioPlayer();
  Timer? _sleepTimer;
  File? _tempAudioFile;
  
  bool get isPlaying => _player.playing;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;

  Future<void> play({
    required double leftFrequency,
    required double rightFrequency,
    double volume = 0.5,
    String? title,
    String? artist,
  }) async {
    await stop();
    
    // Generate audio in background isolate to not block UI
    // Duration is automatically calculated for seamless looping
    final params = BinauralParams(
      leftFrequency: leftFrequency,
      rightFrequency: rightFrequency,
      volume: volume,
    );
    
    final audioData = await compute(_generateBinauralBeatIsolate, params);
    
    // Calculate beat frequency for display
    final beatFreq = (rightFrequency - leftFrequency).abs();
    final mediaItem = MediaItem(
      id: 'binaural_beat_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Binaural Beat',
      artist: artist ?? '${beatFreq.toStringAsFixed(1)} Hz',
      album: 'Beats by Arch',
    );

    AudioSource audioSource;
    
    if (kIsWeb) {
      // On web, we can't use the filesystem, so we play from bytes URI
      audioSource = AudioSource.uri(
        Uri.dataFromBytes(audioData, mimeType: 'audio/wav'),
        tag: mediaItem,
      );
    } else {
      // Write to temporary file (more reliable in release mode on native than StreamAudioSource)
      final tempDir = await getTemporaryDirectory();
      _tempAudioFile = File('${tempDir.path}/binaural_beat.wav');
      await _tempAudioFile!.writeAsBytes(audioData);
      
      audioSource = AudioSource.file(
        _tempAudioFile!.path,
        tag: mediaItem,
      );
    }
    
    await _player.setAudioSource(audioSource);
    await _player.setLoopMode(LoopMode.one);
    await _player.play();
  }

  Future<void> stop() async {
    _cancelSleepTimer();
    await _player.stop();
    
    // Clean up temp file
    if (!kIsWeb && _tempAudioFile != null && await _tempAudioFile!.exists()) {
      try {
        await _tempAudioFile!.delete();
      } catch (_) {
        // Ignore deletion errors
      }
    }
    _tempAudioFile = null;
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  void setVolume(double volume) {
    _player.setVolume(volume);
  }

  void setSleepTimer(Duration duration, VoidCallback onComplete) {
    _cancelSleepTimer();
    _sleepTimer = Timer(duration, () async {
      await stop();
      onComplete();
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
  }

  bool get hasSleepTimer => _sleepTimer != null;

  void dispose() {
    _cancelSleepTimer();
    _player.dispose();
    // Clean up temp file on dispose
    if (!kIsWeb && _tempAudioFile != null) {
      _tempAudioFile!.delete().catchError((_) => _tempAudioFile!);
    }
  }
}

typedef VoidCallback = void Function();
