class WebBinauralBridge {
  static bool get isSupported => false;

  static void init({
    required void Function(bool isPlaying) onStateChanged,
    required void Function() onSleepTimerComplete,
  }) {}

  static void play({
    required double leftFrequency,
    required double rightFrequency,
    required double volume,
    String? title,
    String? artist,
  }) {}

  static void stop() {}

  static void setVolume(double volume) {}

  static void setSleepTimer(int durationSeconds) {}

  static void clearSleepTimer() {}

  static int getRemainingSeconds() => -1;
}

