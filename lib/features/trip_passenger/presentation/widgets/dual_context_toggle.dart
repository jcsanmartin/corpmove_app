import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    // Paletas de colores definidas
    final personalColor = Colors.blue.shade700;
    final corporateColor = const Color(0xFF00C853); // Verde Esmeralda
    final corporateBg = Colors.black87;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isCorporate ? corporateBg : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Fondo animado del indicador (la "pastilla" seleccionada)
          AnimatedAlign(
            alignment:
                isCorporate ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isCorporate ? corporateColor : personalColor,
                  borderRadius: BorderRadius.circular(26),
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
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.inter(
                        color: isCorporate ? Colors.white54 : Colors.white,
                        fontWeight: FontWeight.w600,
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
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.inter(
                        color: isCorporate ? Colors.black : personalColor,
                        fontWeight: FontWeight.w600,
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
