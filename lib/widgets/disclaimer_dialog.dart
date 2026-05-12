import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DisclaimerDialog extends StatelessWidget {
  final VoidCallback onAccept;

  const DisclaimerDialog({super.key, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0D12),
              Color(0xFF000000),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1E1E2E)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFB74D),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Important Notice',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Medical Disclaimer Section
              _buildSection(
                icon: Icons.medical_information_outlined,
                iconColor: const Color(0xFFE57373),
                title: 'Medical Disclaimer',
                content:
                    'This app is for relaxation and entertainment purposes only. '
                    'It is NOT intended to diagnose, treat, cure, or prevent '
                    'any disease or medical condition. Do not use as a substitute '
                    'for professional medical advice.',
              ),
              const SizedBox(height: 18),

              // Epilepsy Warning Section
              _buildSection(
                icon: Icons.flash_on_rounded,
                iconColor: const Color(0xFFFFD54F),
                title: 'Epilepsy & Photosensitivity Warning',
                content:
                    'This app contains visual effects that may trigger seizures '
                    'in people with photosensitive epilepsy. If you have a history '
                    'of epilepsy or seizures, consult a physician before use. '
                    'Stop immediately if you experience dizziness, altered vision, '
                    'or disorientation.',
              ),
              const SizedBox(height: 18),

              // Headphone notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB4A7D6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFB4A7D6).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.headphones_rounded,
                      color: Color(0xFFB4A7D6),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Use stereo headphones at a comfortable volume for the best experience.',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFB4A7D6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Accept Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB4A7D6),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'I Understand',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: iconColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

/// Shows the disclaimer dialog.
/// Returns a Future that completes when the user accepts.
Future<void> showDisclaimerDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (context) => DisclaimerDialog(
      onAccept: () => Navigator.of(context).pop(),
    ),
  );
}
