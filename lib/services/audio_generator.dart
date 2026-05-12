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
  final int numSamples;

  BinauralParams({
    required this.leftFrequency,
    required this.rightFrequency,
    this.volume = 0.5,
    int? sampleRate,
    int? targetDurationSeconds,
  })  : sampleRate = sampleRate ?? 44100,
        numSamples = _calculateSeamlessLoopSamples(
          leftFrequency,
          rightFrequency,
          sampleRate ?? 44100,
          targetDurationSeconds ?? 60,
        );

  /// Calculate the number of samples where both frequencies complete whole cycles
  /// This ensures the sine waves align perfectly at the loop boundary
  static int _calculateSeamlessLoopSamples(
    double leftFreq, double rightFreq, int sampleRate, int targetDuration) {
    final targetSamples = targetDuration * sampleRate;
    int bestSamples = targetSamples;
    double minError = double.infinity;

    // Search +/- 1 second around target for best alignment
    for (int n = targetSamples - sampleRate; n <= targetSamples + sampleRate; n++) {
      if (n <= 0) continue;

      double leftCycles = n * leftFreq / sampleRate;
      double rightCycles = n * rightFreq / sampleRate;

      double leftError = (leftCycles - leftCycles.roundToDouble()).abs();
      double rightError = (rightCycles - rightCycles.roundToDouble()).abs();
      double totalError = leftError + rightError;

      if (totalError < minError) {
        minError = totalError;
        bestSamples = n;
      }

      if (totalError < 0.000001) break;
    }

    return bestSamples;
  }
}

/// Generate binaural beat audio data in a background isolate
Uint8List _generateBinauralBeatIsolate(BinauralParams params) {
  final numSamples = params.numSamples;
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
  final maxAmplitude = (32767 * params.volume).toInt();
  final twoPi = 2 * pi;
  
  // Apply a very small fade (100ms) at the start and end to prevent clicks
  // during the browser's loop transition
  final fadeSamples = (params.sampleRate * 0.1).toInt();

  for (int i = 0; i < numSamples; i++) {
    final t = i / params.sampleRate;
    double fade = 1.0;
    
    if (i < fadeSamples) {
      fade = i / fadeSamples;
    } else if (i > numSamples - fadeSamples) {
      fade = (numSamples - i) / fadeSamples;
    }

    // Left channel - base frequency
    final leftSample = (sin(twoPi * params.leftFrequency * t) * maxAmplitude * fade).toInt();
    buffer.setInt16(offset, leftSample, Endian.little);
    offset += 2;

    // Right channel - base frequency + beat frequency
    final rightSample = (sin(twoPi * params.rightFrequency * t) * maxAmplitude * fade).toInt();
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
      // On web, we generate a much longer clip (10 mins) and use a lower sample rate
      // to avoid browser looping gaps while keeping memory usage reasonable (~50MB).
      // The 100ms fade-out at the end of the 10-min clip prevents audible clicks.
      final webParams = BinauralParams(
        leftFrequency: leftFrequency,
        rightFrequency: rightFrequency,
        volume: volume,
        sampleRate: 22050, // 22kHz is plenty for binaural sine waves
        targetDurationSeconds: 600, // 10 minutes
      );
      
      final webAudioData = await compute(_generateBinauralBeatIsolate, webParams);
      
      audioSource = AudioSource.uri(
        Uri.dataFromBytes(webAudioData, mimeType: 'audio/wav'),
        tag: mediaItem,
      );
    } else {
      // On native, short 60s sample-perfect loops work well
      final nativeParams = BinauralParams(
        leftFrequency: leftFrequency,
        rightFrequency: rightFrequency,
        volume: volume,
        targetDurationSeconds: 60,
      );
      
      final nativeAudioData = await compute(_generateBinauralBeatIsolate, nativeParams);
      
      // Write to temporary file
      final tempDir = await getTemporaryDirectory();
      _tempAudioFile = File('${tempDir.path}/binaural_beat.wav');
      await _tempAudioFile!.writeAsBytes(nativeAudioData);
      
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
