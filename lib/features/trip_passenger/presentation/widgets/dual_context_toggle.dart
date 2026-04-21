import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';

enum TripMode { personal, corporate }

class DualContextToggle extends StatelessWidget {
  final TripMode currentMode;
  final ValueChanged<TripMode> onModeChanged;

  const DualContextToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCorporate = currentMode == TripMode.corporate;

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Fondo animado del indicador
          AnimatedAlign(
            alignment:
                isCorporate ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accentLime,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // Botones
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onModeChanged(TripMode.personal),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 280),
                      style: GoogleFonts.inter(
                        color: !isCorporate
                            ? AppColors.textOnAccent
                            : AppColors.textMuted,
                        fontWeight:
                            !isCorporate ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      child: const Text('Personal'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onModeChanged(TripMode.corporate),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 280),
                      style: GoogleFonts.inter(
                        color: isCorporate
                            ? AppColors.textOnAccent
                            : AppColors.textMuted,
                        fontWeight:
                            isCorporate ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      child: const Text('Corporativo'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
