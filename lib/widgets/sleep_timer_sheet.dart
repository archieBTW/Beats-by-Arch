import 'package:flutter/material.dart';

class SleepTimerSheet extends StatefulWidget {
  final Duration? currentTimer;
  final Function(Duration?) onTimerSet;

  const SleepTimerSheet({
    super.key,
    this.currentTimer,
    required this.onTimerSet,
  });

  @override
  State<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  int? _selectedMinutes;

  static const List<int> _presetMinutes = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    if (widget.currentTimer != null) {
      _selectedMinutes = widget.currentTimer!.inMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(
                Icons.bedtime_outlined,
                color: Color(0xFFB4A7D6),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Sleep Timer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_selectedMinutes != null)
                TextButton(
                  onPressed: () {
                    widget.onTimerSet(null);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel Timer',
                    style: TextStyle(
                      color: Color(0xFFE57373),
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Audio will stop after the selected time',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _presetMinutes.map((minutes) {
              final isSelected = _selectedMinutes == minutes;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMinutes = minutes;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFB4A7D6).withValues(alpha: 0.2)
                        : const Color(0xFF2A2A3A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFB4A7D6)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        minutes < 60 ? '$minutes' : '${minutes ~/ 60}',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFB4A7D6)
                              : Colors.white70,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        minutes < 60 ? 'min' : 'hr${minutes > 60 ? "s" : ""}',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFB4A7D6).withValues(alpha: 0.7)
                              : Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedMinutes != null
                  ? () {
                      widget.onTimerSet(Duration(minutes: _selectedMinutes!));
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB4A7D6),
                foregroundColor: const Color(0xFF1A1A2A),
                disabledBackgroundColor: const Color(0xFF2A2A3A),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _selectedMinutes != null
                    ? 'Set Timer for ${_formatDuration(Duration(minutes: _selectedMinutes!))}'
                    : 'Select Duration',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '$hours hr $minutes min';
      }
      return '$hours hour${hours > 1 ? "s" : ""}';
    }
    return '${duration.inMinutes} minutes';
  }
}
