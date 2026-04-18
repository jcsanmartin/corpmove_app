import 'package:flutter/material.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/screens/negotiation_radar_screen.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/map_placeholder.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/dual_mode_selector.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  bool _isCorporateMode = true;
  final double _techoCobertura = 15000.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const MapPlaceholder(),
          // Barra de búsqueda flotante
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search, color: Color(0xFF1A237E), size: 22),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '¿A dónde vamos?',
                          style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    // Indicador de saldo
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                      child: Container(
                        key: ValueKey(_isCorporateMode),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isCorporateMode ? Colors.orange.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 18,
                              color: _isCorporateMode ? Colors.orange.shade700 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isCorporateMode ? '\$${_techoCobertura.toStringAsFixed(0)}' : 'Efectivo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isCorporateMode ? Colors.orange.shade800 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Botón de ubicación
          Positioned(
            right: 20,
            bottom: 200,
            child: FloatingActionButton(
              heroTag: 'location',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A237E),
              elevation: 4,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Centrando ubicación...'), duration: Duration(seconds: 1)),
                );
              },
              child: const Icon(Icons.my_location),
            ),
          ),
          // Panel inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DualModeSelector(
                    isCorporateMode: _isCorporateMode,
                    onModeChanged: (value) => setState(() => _isCorporateMode = value),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NegotiationRadarScreen()),
                        );
                      },
                      icon: const Icon(Icons.search, size: 22),
                      label: Text(
                        _isCorporateMode
                            ? 'Buscar viaje corporativo'
                            : 'Buscar viaje personal',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCorporateMode ? const Color(0xFF1A237E) : const Color(0xFFFF6D00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                    ),
                  ),
                  if (_isCorporateMode) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Techo de cobertura: \$${_techoCobertura.toStringAsFixed(0)} por viaje',
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}