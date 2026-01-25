import 'package:flutter/material.dart';

class BinauralPreset {
  final String id;
  final String name;
  final String description;
  final double baseFrequency;
  final double beatFrequency;
  final IconData icon;
  final Color accentColor;

  const BinauralPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.baseFrequency,
    required this.beatFrequency,
    required this.icon,
    required this.accentColor,
  });

  // Left ear frequency
  double get leftFrequency => baseFrequency;
  
  // Right ear frequency (slightly higher to create the beat)
  double get rightFrequency => baseFrequency + beatFrequency;

  // Brain wave category based on beat frequency
  String get waveType {
    if (beatFrequency <= 4) return 'Delta';
    if (beatFrequency <= 8) return 'Theta';
    if (beatFrequency <= 14) return 'Alpha';
    if (beatFrequency <= 30) return 'Beta';
    return 'Gamma';
  }
}

class Presets {
  static const Color lavender = Color(0xFFB4A7D6);
  static const Color deepLavender = Color(0xFF9B8AC4);
  static const Color softPurple = Color(0xFFD4C4E8);
  static const Color mintLavender = Color(0xFFA8D4D6);
  static const Color roseLavender = Color(0xFFD6A7C4);
  static const Color goldLavender = Color(0xFFD6C4A7);

  static final List<BinauralPreset> all = [
    BinauralPreset(
      id: 'focus',
      name: 'Focus',
      description: 'Beta waves for concentration and alertness',
      baseFrequency: 200,
      beatFrequency: 18, // Beta range (14-30 Hz)
      icon: Icons.center_focus_strong,
      accentColor: lavender,
    ),
    BinauralPreset(
      id: 'flow',
      name: 'Flow State',
      description: 'Alpha waves for relaxed focus and performance',
      baseFrequency: 200,
      beatFrequency: 10, // Alpha range (8-14 Hz)
      icon: Icons.waves,
      accentColor: mintLavender,
    ),
    BinauralPreset(
      id: 'aha',
      name: 'Aha Moments',
      description: 'Gamma waves for insight and problem solving',
      baseFrequency: 200,
      beatFrequency: 40, // Gamma range (30+ Hz)
      icon: Icons.lightbulb,
      accentColor: goldLavender,
    ),
    BinauralPreset(
      id: 'meditation',
      name: 'Meditation',
      description: 'Theta waves for deep meditation and relaxation',
      baseFrequency: 150,
      beatFrequency: 6, // Theta range (4-8 Hz)
      icon: Icons.self_improvement,
      accentColor: deepLavender,
    ),
    BinauralPreset(
      id: 'creativity',
      name: 'Creativity',
      description: 'Theta-Alpha border for creative inspiration',
      baseFrequency: 180,
      beatFrequency: 7.83, // Schumann resonance
      icon: Icons.palette,
      accentColor: roseLavender,
    ),
    BinauralPreset(
      id: 'sleep',
      name: 'Deep Sleep',
      description: 'Delta waves for restorative deep sleep',
      baseFrequency: 100,
      beatFrequency: 2, // Delta range (0.5-4 Hz)
      icon: Icons.bedtime,
      accentColor: softPurple,
    ),
  ];
}
