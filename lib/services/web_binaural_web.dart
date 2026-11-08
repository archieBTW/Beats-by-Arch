import 'dart:js_interop';

@JS('binauralEngine')
external JSObject? get _binauralEngine;

@JS('binauralEngine.play')
external void _binauralPlay(
    num leftFreq, num rightFreq, num volume, JSString title, JSString artist);

@JS('binauralEngine.stop')
external void _binauralStop();

@JS('binauralEngine.setVolume')
external void _binauralSetVolume(num volume);

@JS('binauralEngine.setSleepTimer')
external void _binauralSetSleepTimer(num seconds);

@JS('binauralEngine.clearSleepTimer')
external void _binauralClearSleepTimer();

@JS('binauralEngine.getRemainingSeconds')
external num _binauralGetRemainingSeconds();

@JS('binauralEngine.isPlaying')
external bool _binauralIsPlaying();

@JS('binauralEngine.setOnStateChange')
external void _binauralSetOnStateChange(JSFunction? callback);

@JS('binauralEngine.setOnSleepComplete')
external void _binauralSetOnSleepComplete(JSFunction? callback);

class WebBinauralBridge {
  static bool _initialized = false;

  static bool get isSupported {
    try {
      return _binauralEngine != null;
    } catch (_) {
      return false;
    }
  }

  static bool get isPlaying {
    if (!isSupported) return false;
    try {
      return _binauralIsPlaying();
    } catch (_) {
      return false;
    }
  }

  static void init({
    required void Function(bool isPlaying) onStateChanged,
    required void Function() onSleepTimerComplete,
  }) {
    if (_initialized || !isSupported) return;
    _initialized = true;

    try {
      final stateCallback = ((JSBoolean playing) {
        onStateChanged(playing.toDart);
      }).toJS;

      final sleepCallback = (() {
        onSleepTimerComplete();
      }).toJS;

      _binauralSetOnStateChange(stateCallback);
      _binauralSetOnSleepComplete(sleepCallback);
    } catch (_) {}
  }

  static void play({
    required double leftFrequency,
    required double rightFrequency,
    required double volume,
    String? title,
    String? artist,
  }) {
    if (!isSupported) return;
    try {
      _binauralPlay(
        leftFrequency,
        rightFrequency,
        volume,
        (title ?? 'Binaural Beat').toJS,
        (artist ?? 'Beats by Arch').toJS,
      );
    } catch (_) {}
  }

  static void stop() {
    if (!isSupported) return;
    try {
      _binauralStop();
    } catch (_) {}
  }

  static void setVolume(double volume) {
    if (!isSupported) return;
    try {
      _binauralSetVolume(volume);
    } catch (_) {}
  }

  static void setSleepTimer(int durationSeconds) {
    if (!isSupported) return;
    try {
      _binauralSetSleepTimer(durationSeconds);
    } catch (_) {}
  }

  static void clearSleepTimer() {
    if (!isSupported) return;
    try {
      _binauralClearSleepTimer();
    } catch (_) {}
  }

  static int getRemainingSeconds() {
    if (!isSupported) return -1;
    try {
      return _binauralGetRemainingSeconds().toInt();
    } catch (_) {
      return -1;
    }
  }
}
