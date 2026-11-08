import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;

import 'web_binaural_stub.dart'
    if (dart.library.html) 'web_binaural_web.dart';

/// Parameters for generating binaural beats in isolate (Native fallback)
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
  /// This ensures the sine waves align perfectly at the loop boundary without any fade dip
  static int _calculateSeamlessLoopSamples(
      double leftFreq, double rightFreq, int sampleRate, int targetDuration) {
    final targetSamples = targetDuration * sampleRate;
    int bestSamples = targetSamples;
    double minError = double.infinity;

    // Search +/- 2 seconds around target for phase-locked zero-crossing alignment
    for (int n = targetSamples - (sampleRate * 2);
        n <= targetSamples + (sampleRate * 2);
        n++) {
      if (n <= 0) continue;

      final double leftCycles = n * leftFreq / sampleRate;
      final double rightCycles = n * rightFreq / sampleRate;

      final double leftError = (leftCycles - leftCycles.roundToDouble()).abs();
      final double rightError =
          (rightCycles - rightCycles.roundToDouble()).abs();
      final double totalError = leftError + rightError;

      if (totalError < minError) {
        minError = totalError;
        bestSamples = n;
      }

      if (totalError < 0.000001) break;
    }

    return bestSamples;
  }
}

/// Generate phase-continuous binaural beat audio data in a background isolate
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

  // Generate pure phase-aligned sine samples with zero boundary fade dip
  // Because numSamples is calculated for exact whole cycles, sample 0 and sample numSamples
  // meet at a clean zero-crossing with matching slope.
  final maxAmplitude = (32767 * params.volume).toInt();
  final twoPi = 2 * pi;

  // Exact frequencies adjusted by tiny fraction so the loop boundary is 100% phase-continuous
  final leftCycles =
      (numSamples * params.leftFrequency / params.sampleRate).roundToDouble();
  final rightCycles =
      (numSamples * params.rightFrequency / params.sampleRate).roundToDouble();
  final exactLeftStep = twoPi * leftCycles / numSamples;
  final exactRightStep = twoPi * rightCycles / numSamples;

  for (int i = 0; i < numSamples; i++) {
    final leftSample = (sin(exactLeftStep * i) * maxAmplitude).toInt();
    buffer.setInt16(offset, leftSample, Endian.little);
    offset += 2;

    final rightSample = (sin(exactRightStep * i) * maxAmplitude).toInt();
    buffer.setInt16(offset, rightSample, Endian.little);
    offset += 2;
  }

  return buffer.buffer.asUint8List();
}

/// Service for managing binaural beat playback
/// Uses real-time Web Audio API synthesis on Web for instant startup, zero loop clicks,
/// and uninterrupted background tab playback.
class BinauralBeatService {
  AudioPlayer? _nativePlayer;
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  bool _isPlaying = false;
  double _volume = 0.5;
  Timer? _sleepTimer;
  VoidCallback? _onSleepTimerComplete;
  File? _tempAudioFile;

  BinauralBeatService() {
    if (kIsWeb && WebBinauralBridge.isSupported) {
      WebBinauralBridge.init(
        onStateChanged: (playing) {
          _isPlaying = playing;
          if (!_playingController.isClosed) {
            _playingController.add(playing);
          }
        },
        onSleepTimerComplete: () {
          _isPlaying = false;
          if (!_playingController.isClosed) {
            _playingController.add(false);
          }
          final cb = _onSleepTimerComplete;
          _onSleepTimerComplete = null;
          cb?.call();
        },
      );
    } else {
      _nativePlayer = AudioPlayer();
      _nativePlayer!.playingStream.listen((playing) {
        _isPlaying = playing;
        if (!_playingController.isClosed) {
          _playingController.add(playing);
        }
      });
    }
  }

  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  Stream<bool> get playingStream => _playingController.stream;

  Future<void> play({
    required double leftFrequency,
    required double rightFrequency,
    double? volume,
    String? title,
    String? artist,
  }) async {
    if (volume != null) {
      _volume = volume;
    }

    final beatFreq = (rightFrequency - leftFrequency).abs();
    final effectiveTitle = title ?? 'Binaural Beat';
    final effectiveArtist = artist ?? '${beatFreq.toStringAsFixed(1)} Hz';

    if (kIsWeb && WebBinauralBridge.isSupported) {
      WebBinauralBridge.play(
        leftFrequency: leftFrequency,
        rightFrequency: rightFrequency,
        volume: _volume,
        title: effectiveTitle,
        artist: effectiveArtist,
      );
      return;
    }

    // Native fallback
    await stop();
    final player = _nativePlayer ??= AudioPlayer();

    final mediaItem = MediaItem(
      id: 'binaural_beat_${DateTime.now().millisecondsSinceEpoch}',
      title: effectiveTitle,
      artist: effectiveArtist,
      album: 'Beats by Arch',
    );

    final nativeParams = BinauralParams(
      leftFrequency: leftFrequency,
      rightFrequency: rightFrequency,
      volume: _volume,
      targetDurationSeconds: 60,
    );

    final nativeAudioData =
        await compute(_generateBinauralBeatIsolate, nativeParams);

    AudioSource audioSource;
    if (kIsWeb) {
      audioSource = AudioSource.uri(
        Uri.dataFromBytes(nativeAudioData, mimeType: 'audio/wav'),
        tag: mediaItem,
      );
    } else {
      final tempDir = await getTemporaryDirectory();
      _tempAudioFile = File('${tempDir.path}/binaural_beat.wav');
      await _tempAudioFile!.writeAsBytes(nativeAudioData);

      audioSource = AudioSource.file(
        _tempAudioFile!.path,
        tag: mediaItem,
      );
    }

    await player.setAudioSource(audioSource);
    await player.setLoopMode(LoopMode.one);
    await player.play();
  }

  Future<void> stop() async {
    _cancelSleepTimer();

    if (kIsWeb && WebBinauralBridge.isSupported) {
      WebBinauralBridge.stop();
      return;
    }

    await _nativePlayer?.stop();

    if (!kIsWeb && _tempAudioFile != null && await _tempAudioFile!.exists()) {
      try {
        await _tempAudioFile!.delete();
      } catch (_) {}
    }
    _tempAudioFile = null;
  }

  Future<void> pause() async {
    if (kIsWeb && WebBinauralBridge.isSupported) {
      WebBinauralBridge.stop();
      return;
    }
    await _nativePlayer?.pause();
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    if (kIsWeb && WebBinauralBridge.isSupported) {
      WebBinauralBridge.setVolume(_volume);
      return;
    }
    _nativePlayer?.setVolume(_volume);
  }

  void setSleepTimer(Duration duration, VoidCallback onComplete) {
    _cancelSleepTimer();
    _onSleepTimerComplete = onComplete;

    if (kIsWeb && WebBinauralBridge.isSupported) {
      WebBinauralBridge.setSleepTimer(duration.inSeconds);
      return;
    }

    _sleepTimer = Timer(duration, () async {
      await stop();
      onComplete();
    });
  }

  Duration? getRemainingSleepTime() {
    if (kIsWeb && WebBinauralBridge.isSupported) {
      final secs = WebBinauralBridge.getRemainingSeconds();
      if (secs >= 0) {
        return Duration(seconds: secs);
      }
      return null;
    }
    return null;
  }

  void cancelSleepTimer() {
    _cancelSleepTimer();
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _onSleepTimerComplete = null;
    if (kIsWeb && WebBinauralBridge.isSupported) {
      WebBinauralBridge.clearSleepTimer();
    }
  }

  bool get hasSleepTimer => _sleepTimer != null || _onSleepTimerComplete != null;

  void dispose() {
    _cancelSleepTimer();
    if (kIsWeb && WebBinauralBridge.isSupported) {
      WebBinauralBridge.stop();
    }
    _nativePlayer?.dispose();
    _playingController.close();
    if (!kIsWeb && _tempAudioFile != null) {
      _tempAudioFile!.delete().catchError((_) => _tempAudioFile!);
    }
  }
}

typedef VoidCallback = void Function();
