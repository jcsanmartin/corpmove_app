import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  final String? activeTripId;

  const QRScannerScreen({super.key, this.activeTripId});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = true;

  Future<void> _handleCheckIn(String vehicleId) async {
    setState(() => _isScanning = false);

    try {
      final supabase = Supabase.instance.client;

      // Si no tenemos un tripId específico, buscamos el más reciente 'accepted' para este usuario
      String? tripId = widget.activeTripId;
      
      if (tripId == null) {
        final user = supabase.auth.currentUser;
        if (user == null) {
          _showError("Usuario no autenticado en Supabase.");
          return;
        }

        final latestTrip = await supabase
            .from('trips')
            .select('id')
            .eq('user_id', user.id)
            .eq('status', 'accepted')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        tripId = latestTrip?['id'];
      }

      if (tripId == null) {
        _showError("No se encontró un viaje activo para hacer check-in.");
        return;
      }

      // Actualizar estado del viaje
      await supabase.from('trips').update({
        'status': 'in_progress',
        'vehicle_id': vehicleId,
        'checkin_at': DateTime.now().toIso8601String(),
      }).eq('id', tripId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Check-in realizado con éxito. ¡Buen viaje!"),
            backgroundColor: AppColors.accentLime,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError("Error al realizar check-in: $e");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text("Error de Check-in", style: GoogleFonts.inter(color: AppColors.error)),
        content: Text(message, style: GoogleFonts.inter(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isScanning = true);
            },
            child: const Text("Reintentar", style: TextStyle(color: AppColors.accentLime)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar", style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Check-in con QR", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.scaffoldLight,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (!_isScanning) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  try {
                    final data = jsonDecode(code);
                    if (data['type'] == 'checkin' && data['vehicle_id'] != null) {
                      _handleCheckIn(data['vehicle_id']);
                      break;
                    }
                  } catch (e) {
                    // No es un JSON válido o no es nuestro QR
                  }
                }
              }
            },
          ),
          // Overlay para guiar al usuario
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accentLime, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accentLime, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    "Escanea el código QR del vehículo",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Asegúrate de estar dentro del vehículo asignado",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
