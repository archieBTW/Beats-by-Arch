import 'dart:math';
import 'package:flutter/material.dart';

class WaveVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double beatFrequency;

  const WaveVisualizer({
    super.key,
    required this.isPlaying,
    required this.color,
    required this.beatFrequency,
  });

  @override
  State<WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<WaveVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: (1000 / widget.beatFrequency).round()),
      vsync: this,
    );

    if (widget.isPlaying) {
      _waveController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _waveController.repeat();
        _pulseController.repeat(reverse: true);
      } else {
        _waveController.stop();
        _pulseController.stop();
      }
    }
    if (widget.beatFrequency != oldWidget.beatFrequency) {
      _pulseController.duration =
          Duration(milliseconds: (1000 / widget.beatFrequency).round());
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(
            waveProgress: _waveController.value,
            pulseProgress: _pulseController.value,
            color: widget.color,
            isPlaying: widget.isPlaying,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double waveProgress;
  final double pulseProgress;
  final Color color;
  final bool isPlaying;

  _WavePainter({
    required this.waveProgress,
    required this.pulseProgress,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final amplitude = isPlaying ? 20.0 + (pulseProgress * 15) : 10.0;
    
    // Draw multiple wave layers
    for (int layer = 0; layer < 3; layer++) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.1 - (layer * 0.03))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 - (layer * 0.5);

      final path = Path();
      final layerOffset = layer * 0.3;
      final layerAmplitude = amplitude * (1 - layer * 0.2);

      for (double x = 0; x <= size.width; x++) {
        final normalizedX = x / size.width;
        final y = centerY +
            sin((normalizedX * 4 * pi) + (waveProgress * 2 * pi) + layerOffset) *
                layerAmplitude;

        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }

    // Draw center glow when playing
    if (isPlaying) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.05 + (pulseProgress * 0.05))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

      canvas.drawCircle(
        Offset(size.width / 2, centerY),
        50 + (pulseProgress * 20),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return waveProgress != oldDelegate.waveProgress ||
        pulseProgress != oldDelegate.pulseProgress ||
        color != oldDelegate.color ||
        isPlaying != oldDelegate.isPlaying;
  }
}
