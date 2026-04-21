import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/passenger_trip_provider.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
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

        return Container(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
          decoration: AppDecorations.bottomSheet,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de arrastre (grabber)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Ofrece tu tarifa',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Input de tarifa
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 180,
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderAccent),
                    ),
                    child: TextField(
                      controller: _fareController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (value) {
                        final fare = double.tryParse(value) ?? 0.0;
                        provider.setProposedFare(fare);
                      },
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        prefixStyle: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Botón de Ofertar
                  ElevatedButton(
                    onPressed: () {
                      // Simular envío
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Buscando conductores...'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLime,
                      foregroundColor: AppColors.textOnAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ofertar',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              // Lógica de Subsidio y Excedente
              if (isCorporate) ...[
                const SizedBox(height: 24),
                _buildSurplusAlert(provider),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurplusAlert(PassengerTripProvider provider) {
    if (provider.isLoadingLimit) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentLime),
      );
    }

    final surplus = provider.surplusAmount;

    if (surplus > 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Supera el techo corporativo de \$${provider.corporateLimit.toStringAsFixed(0)}. Excedente: \$${surplus.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentLime.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentLime.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentLime.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.textOnAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cubierto 100% por corporativo. (Límite: \$${provider.corporateLimit.toStringAsFixed(0)})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
