import 'package:flutter/material.dart';
import '../models/preset.dart';

class PresetCard extends StatelessWidget {
  final BinauralPreset preset;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;

  const PresetCard({
    super.key,
    required this.preset,
    required this.isSelected,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    preset.accentColor.withValues(alpha: 0.3),
                    preset.accentColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? preset.accentColor
                : const Color(0xFF1E1E2E),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: preset.accentColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? preset.accentColor.withValues(alpha: 0.2)
                          : const Color(0xFF12121A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      preset.icon,
                      color: isSelected
                          ? preset.accentColor
                          : Colors.white60,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected && isPlaying)
                    _PulsingIndicator(color: preset.accentColor),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                preset.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  preset.description,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white60
                        : Colors.white38,
                    fontSize: 11,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? preset.accentColor.withValues(alpha: 0.2)
                      : const Color(0xFF12121A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${preset.waveType} • ${preset.beatFrequency.toStringAsFixed(1)} Hz',
                  style: TextStyle(
                    color: isSelected
                        ? preset.accentColor
                        : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingIndicator extends StatefulWidget {
  final Color color;

  const _PulsingIndicator({required this.color});

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
