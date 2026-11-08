# Beats by Arch 🎧⚡

A high-performance, web-first binaural beat generator designed for focus, meditation, relaxation, and deep sleep. Built with Flutter Web and powered by a low-latency Web Audio API synthesis engine.

Visit the live app: [beats.archerwoods.dev](https://beats.archerwoods.dev)

---

## ✨ Features

- **Pure Real-Time Synthesis**: Generates seamless sine-wave binaural beats on the fly using the browser's native `AudioContext` and `StereoPannerNode` / `ChannelMergerNode`. No static audio files, no buffer looping, and zero audio clicks or phase resets.
- **Instant Response**: Audio starts instantaneously with smooth exponential frequency transitions (`setTargetAtTime`), preventing pops or abrupt acoustic shifts.
- **Uninterrupted Background Playback**:
  - Integrated with the **MediaSession API** for browser media controls and lock-screen presence.
  - Utilizes a persistent `MediaStreamAudioDestinationNode` keepalive loop to prevent browser throttling when switching tabs or backgrounding the window.
  - Implements the **Screen Wake Lock API** to keep audio active during deep focus and sleep sessions.
- **Brainwave Presets**:
  - **Delta (0.5 – 4 Hz)**: Deep restorative sleep, physical healing, and unconscious recovery.
  - **Theta (4 – 8 Hz)**: Deep meditation, REM sleep, intuition, and subconscious creativity.
  - **Alpha (8 – 14 Hz)**: Relaxed alertness, stress reduction, and effortless flow state.
  - **Beta (14 – 30 Hz)**: Active focus, analytical problem-solving, and cognitive alertness.
  - **Gamma (30 – 50 Hz)**: High-level information processing, peak cognition, and transcendental focus.
- **Custom Frequency Fine-Tuning**: Full slider control over both the carrier frequency (100 Hz – 500 Hz) and target beat frequency (0.5 Hz – 50 Hz).
- **Accurate Sleep Timer**: Countdown timer backed by wall-clock epoch timestamps (`Date.now()`), ensuring precise duration tracking even when backgrounded, followed by a gentle volume fade-out.
- **Cross-Platform Responsive UI**: Beautiful dark-mode design optimized for mobile and desktop screens.

---

## 🛠️ Architecture

- **Frontend**: Flutter Web (Dart 3)
- **Audio Engine**: Native JavaScript Web Audio API (`window.binauralEngine`), bound via zero-overhead `dart:js_interop` bridges:
  - Left channel: $f_{base}$
  - Right channel: $f_{base} + f_{beat}$
  - Smooth gain envelopes to prevent clipping and pops on start/stop.
- **Native Fallback**: Supports `just_audio` and programmatic PCM WAV generation for native desktop/mobile targets.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.24+ recommended)
- Google Chrome, Safari, or Firefox

### Installation & Development
```bash
# Clone the repository
git clone https://github.com/torrey/beats-by-arch.git
cd beats-by-arch

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome
```

### Production Web Build
```bash
flutter build web --release
```

The compiled output is located in `build/web/`.

---

## 🚢 Deployment

Deployed via the [WE-IAC](https://github.com/torrey/WE-IAC) Infrastructure-as-Code pipeline:
- Automated TLS certificates via Let's Encrypt / Certbot.
- Hardened Nginx reverse proxy with HTTP/2 and asset caching.
- Monitored continuously via the fyrWeb Portfolio infra suite.

---

## 📄 License

MIT License. Designed and maintained by Torrey.
