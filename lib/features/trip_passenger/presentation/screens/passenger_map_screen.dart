import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../application/passenger_trip_provider.dart';
import '../widgets/dual_context_toggle.dart';
import '../widgets/negotiation_bottom_sheet.dart';

class PassengerMapScreen extends StatefulWidget {
  const PassengerMapScreen({super.key});

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  GoogleMapController? _mapController;

  // Ubicación inicial por defecto (ej. Bogotá, Colombia)
  final LatLng _initialCenter = const LatLng(4.6097, -74.0817);

  @override
  Widget build(BuildContext context) {
    // Usamos ChangeNotifierProvider si no está provisto en un nivel superior.
    // Para efectos de modularidad en esta pantalla, lo envolvemos aquí.
    return ChangeNotifierProvider(
      create: (_) => PassengerTripProvider(),
      child: Scaffold(
        body: Stack(
          children: [
            // 1. El Mapa en el fondo
            _buildGoogleMap(),

            // 2. El botón dual de contexto en la parte superior flotante
            const Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: SafeArea(child: _ToggleWrapper()),
            ),

            // BottomSheet interactivo para la negociación
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: NegotiationBottomSheet(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _initialCenter,
        zoom: 14.0,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
    );
  }
}

// Un widget de ayuda para extraer el Consumer del Provider
class _ToggleWrapper extends StatelessWidget {
  const _ToggleWrapper();

  @override
  Widget build(BuildContext context) {
    return Consumer<PassengerTripProvider>(
      builder: (context, provider, child) {
        return DualContextToggle(
          currentMode: provider.currentMode,
          onModeChanged: (mode) {
            provider.setMode(mode);

            // Opcional: mostrar un Snackbar indicando el cambio para la demo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(mode == TripMode.corporate
                    ? 'Modo Corporativo activado'
                    : 'Modo Personal activado'),
                backgroundColor: mode == TripMode.corporate
                    ? const Color(0xFF00C853)
                    : Colors.blue.shade700,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }
}
