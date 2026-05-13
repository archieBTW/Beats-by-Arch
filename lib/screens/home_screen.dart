import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/preset.dart';
import '../services/audio_generator.dart';
import '../widgets/disclaimer_dialog.dart';
import '../widgets/preset_card.dart';
import '../widgets/wave_visualizer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final BinauralBeatService _audioService = BinauralBeatService();
  BinauralPreset? _selectedPreset;
  bool _isPlaying = false;
  Duration? _sleepTimerDuration;
  Duration? _remainingTime;
  Timer? _countdownTimer;
  late AnimationController _playButtonController;

  // Custom frequency mode
  bool _isCustomMode = false;
  double _customBaseFrequency = 200;
  double _customBeatFrequency = 10;

  static const String _disclaimerShownKey = 'disclaimer_shown';

  @override
  void initState() {
    super.initState();
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _audioService.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
        if (playing) {
          _playButtonController.forward();
        } else {
          _playButtonController.reverse();
        }
      }
    });

    // Show disclaimer dialog on first app launch only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowDisclaimer();
    });
  }

  Future<void> _checkAndShowDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenDisclaimer = prefs.getBool(_disclaimerShownKey) ?? false;

    if (!hasSeenDisclaimer && mounted) {
      await showDisclaimerDialog(context);
      await prefs.setBool(_disclaimerShownKey, true);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _playButtonController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  void _selectPreset(BinauralPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _isCustomMode = false;
    });
    if (_isPlaying) {
      _playPreset(preset);
    }
  }

  void _selectCustomMode() {
    setState(() {
      _selectedPreset = null;
      _isCustomMode = true;
    });
    if (_isPlaying) {
      _playCustom();
    }
  }

  Future<void> _playPreset(BinauralPreset preset) async {
    await _audioService.play(
      leftFrequency: preset.leftFrequency,
      rightFrequency: preset.rightFrequency,
      title: preset.name,
      artist: '${preset.beatFrequency} Hz ${preset.waveType} Waves',
    );
  }

  Future<void> _playCustom() async {
    await _audioService.play(
      leftFrequency: _customBaseFrequency,
      rightFrequency: _customBaseFrequency + _customBeatFrequency,
      title: 'Custom',
      artist: '${_customBeatFrequency.toStringAsFixed(1)} Hz',
    );
  }

  void _togglePlayPause() async {
    if (!_isCustomMode && _selectedPreset == null) {
      _showMessage('Select a preset or use custom frequencies');
      return;
    }

    if (_isPlaying) {
      await _audioService.stop();
      _cancelSleepTimer();
    } else {
      if (_isCustomMode) {
        await _playCustom();
      } else {
        await _playPreset(_selectedPreset!);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF12121A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _setSleepTimer(Duration? duration) {
    _cancelSleepTimer();

    if (duration == null) {
      setState(() {
        _sleepTimerDuration = null;
        _remainingTime = null;
      });
      return;
    }

    setState(() {
      _sleepTimerDuration = duration;
      _remainingTime = duration;
    });

    _audioService.setSleepTimer(duration, () {
      if (mounted) {
        setState(() {
          _sleepTimerDuration = null;
          _remainingTime = null;
        });
        _showMessage('Sleep timer ended. Sweet dreams! 🌙');
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _remainingTime != null) {
        setState(() {
          _remainingTime = _remainingTime! - const Duration(seconds: 1);
          if (_remainingTime!.isNegative) {
            _remainingTime = Duration.zero;
          }
        });
      }
    });
  }

  void _cancelSleepTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  String _formatRemainingTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getWaveType(double beatFreq) {
    if (beatFreq <= 4) return 'Delta';
    if (beatFreq <= 8) return 'Theta';
    if (beatFreq <= 14) return 'Alpha';
    if (beatFreq <= 30) return 'Beta';
    return 'Gamma';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;

            if (isDesktop) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildVisualizerSection(isDesktop: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildPresetsSection(
                        isDesktop: true,
                        width: constraints.maxWidth,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: 40,
                      ),
                      child: _buildCustomFrequencySection(isDesktop: true),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildVisualizerSection(),
                        const SizedBox(height: 32),
                        _buildPresetsSection(),
                        const SizedBox(height: 24),
                        _buildCustomFrequencySection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildPlayButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildVisualizerSection({bool isDesktop = false}) {
    final Color color;
    final double beatFreq;
    final String name;
    final double leftFreq;
    final double rightFreq;

    if (_isCustomMode) {
      color = const Color(0xFFB4A7D6);
      beatFreq = _customBeatFrequency;
      name = 'Custom';
      leftFreq = _customBaseFrequency;
      rightFreq = _customBaseFrequency + _customBeatFrequency;
    } else if (_selectedPreset != null) {
      color = _selectedPreset!.accentColor;
      beatFreq = _selectedPreset!.beatFrequency;
      name = _selectedPreset!.name;
      leftFreq = _selectedPreset!.leftFrequency;
      rightFreq = _selectedPreset!.rightFrequency;
    } else {
      color = const Color(0xFFB4A7D6);
      beatFreq = 10.0;
      name = '';
      leftFreq = 0;
      rightFreq = 0;
    }

    final hasSelection = _isCustomMode || _selectedPreset != null;

    return Container(
      height: isDesktop ? 220 : 180,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            WaveVisualizer(
              isPlaying: _isPlaying,
              color: color,
              beatFrequency: beatFreq,
            ),
            if (hasSelection)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPlaying ? 'Now Playing' : 'Selected',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${leftFreq.toInt()} Hz | ${rightFreq.toInt()} Hz',
                        style: GoogleFonts.jetBrainsMono(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!hasSelection)
              Center(
                child: Text(
                  'Select a preset or use custom frequencies',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsSection({bool isDesktop = false, double? width}) {
    int crossAxisCount = 2;
    if (isDesktop) {
      if (width != null && width < 1200) {
        crossAxisCount = 3;
      } else {
        crossAxisCount = 6;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isDesktop) ...[
          Text(
            'PRESETS',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: isDesktop ? 0.85 : 0.95,
          ),
          itemCount: Presets.all.length,
          itemBuilder: (context, index) {
            final preset = Presets.all[index];
            return PresetCard(
              preset: preset,
              isSelected: !_isCustomMode && _selectedPreset?.id == preset.id,
              isPlaying:
                  _isPlaying &&
                  !_isCustomMode &&
                  _selectedPreset?.id == preset.id,
              onTap: () => _selectPreset(preset),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomFrequencySection({bool isDesktop = false}) {
    return GestureDetector(
      onTap: _selectCustomMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 20,
          vertical: 20,
        ),
        decoration: BoxDecoration(
          gradient: _isCustomMode
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFB4A7D6).withValues(alpha: 0.15),
                    const Color(0xFF7B2CBF).withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: _isCustomMode ? null : const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isCustomMode
                ? const Color(0xFFB4A7D6)
                : const Color(0xFF1E1E2E),
            width: _isCustomMode ? 2 : 1,
          ),
          boxShadow: _isCustomMode
              ? [
                  BoxShadow(
                    color: const Color(0xFFB4A7D6).withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1200 : double.infinity,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 2, child: _buildCustomFrequencyHeader()),
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFrequencySliders(),
                            const SizedBox(height: 16),
                            _buildFrequencyInfo(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 2,
                        child: _buildSleepTimerControls(isDesktop: true),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCustomFrequencyHeader(),
                      const SizedBox(height: 24),
                      _buildFrequencySliders(),
                      const SizedBox(height: 16),
                      _buildFrequencyInfo(),
                      _buildSleepTimerControls(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFrequencyHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB4A7D6), Color(0xFF7B2CBF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tune, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Custom Frequencies',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Set your own binaural beat',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (_isCustomMode && _isPlaying) ...[
          const SizedBox(width: 12),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFB4A7D6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB4A7D6).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFrequencySliders() {
    return Column(
      children: [
        _buildFrequencySlider(
          label: 'Base Frequency',
          value: _customBaseFrequency,
          min: 50,
          max: 500,
          unit: 'Hz',
          description: 'Carrier tone frequency',
          onChanged: (value) {
            setState(() {
              _customBaseFrequency = value;
            });
          },
          onChangeEnd: (_) {
            if (_isPlaying && _isCustomMode) {
              _playCustom();
            }
          },
        ),
        const SizedBox(height: 20),
        _buildFrequencySlider(
          label: 'Beat Frequency',
          value: _customBeatFrequency,
          min: 0.5,
          max: 50,
          unit: 'Hz',
          description: _getWaveType(_customBeatFrequency),
          onChanged: (value) {
            setState(() {
              _customBeatFrequency = value;
            });
          },
          onChangeEnd: (_) {
            if (_isPlaying && _isCustomMode) {
              _playCustom();
            }
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.headphones,
            color: Colors.white.withValues(alpha: 0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'L: ${_customBaseFrequency.toInt()} Hz  •  R: ${(_customBaseFrequency + _customBeatFrequency).toInt()} Hz  •  Beat: ${_customBeatFrequency.toStringAsFixed(1)} Hz',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTimerControls({bool isDesktop = false}) {
    final List<int> presetMinutes = [15, 30, 45, 60];
    final hasActiveTimer = _remainingTime != null && _isPlaying;

    return Column(
      crossAxisAlignment: isDesktop
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isDesktop) const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'SLEEP TIMER',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            if (hasActiveTimer)
              Text(
                _formatRemainingTime(_remainingTime!),
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFFB4A7D6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ...presetMinutes.map((minutes) {
              final isSelected = _sleepTimerDuration?.inMinutes == minutes;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      _setSleepTimer(null);
                    } else {
                      _setSleepTimer(Duration(minutes: minutes));
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFB4A7D6).withValues(alpha: 0.2)
                          : const Color(0xFF12121A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFB4A7D6)
                            : Colors.white10,
                      ),
                    ),
                    child: Text(
                      '${minutes}m',
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFB4A7D6)
                            : Colors.white38,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (_sleepTimerDuration != null)
              IconButton(
                onPressed: () => _setSleepTimer(null),
                icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencySlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required String description,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB4A7D6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${value.toStringAsFixed(value < 10 ? 1 : 0)} $unit',
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFFB4A7D6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF7B2CBF),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: const Color(0xFFB4A7D6),
            inactiveTrackColor: const Color(0xFF1E1E2E),
            thumbColor: const Color(0xFFB4A7D6),
            overlayColor: const Color(0xFFB4A7D6).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    final Color color;
    if (_isCustomMode) {
      color = const Color(0xFFB4A7D6);
    } else if (_selectedPreset != null) {
      color = _selectedPreset!.accentColor;
    } else {
      color = const Color(0xFFB4A7D6);
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.7)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
            key: ValueKey(_isPlaying),
            color: Colors.black,
            size: 36,
          ),
        ),
      ),
    );
  }
}
