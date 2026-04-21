import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/passenger_trip_provider.dart';
import 'dual_context_toggle.dart';

class NegotiationBottomSheet extends StatefulWidget {
  const NegotiationBottomSheet({super.key});

  @override
  State<NegotiationBottomSheet> createState() => _NegotiationBottomSheetState();
}

class _NegotiationBottomSheetState extends State<NegotiationBottomSheet> {
  final TextEditingController _fareController = TextEditingController();

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PassengerTripProvider>(
      builder: (context, provider, child) {
        final isCorporate = provider.currentMode == TripMode.corporate;
        final corporateColor = const Color(0xFF00C853);
        final personalColor = Colors.blue.shade700;
        final themeColor = isCorporate ? corporateColor : personalColor;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de arrastre
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Propón tu tarifa',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Input de tarifa
              TextField(
                controller: _fareController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
                onChanged: (value) {
                  final fare = double.tryParse(value) ?? 0.0;
                  provider.setProposedFare(fare);
                },
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                ),
              ),

              // Lógica de Subsidio y Excedente
              if (isCorporate) ...[
                const SizedBox(height: 16),
                _buildSurplusAlert(provider),
              ],

              const SizedBox(height: 24),

              // Botón de Buscar Conductor
              ElevatedButton(
                onPressed: () {
                  // Aquí se llamaría al repositorio para guardar en Firestore
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Buscando conductores...'),
                      backgroundColor: themeColor,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorporate ? Colors.black : personalColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Negociar Tarifa',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCorporate ? corporateColor : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurplusAlert(PassengerTripProvider provider) {
    if (provider.isLoadingLimit) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C853)),
      );
    }

    final surplus = provider.surplusAmount;

    if (surplus > 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'La tarifa supera tu techo de \$${provider.corporateLimit.toStringAsFixed(0)}. Se cobrará un excedente de \$${surplus.toStringAsFixed(0)} a tu tarjeta personal.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF00C853).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00C853)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tarifa cubierta 100% por el subsidio corporativo. (Límite: \$${provider.corporateLimit.toStringAsFixed(0)})',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
