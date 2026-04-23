import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:corpmove_app/core/widgets/custom_map_mapbox.dart';
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

  final GlobalKey<CustomMapMapboxState> _mapKey = GlobalKey();

  // Ubicación inicial (Bogotá, Colombia)
  final double _lat = 4.6097;
  final double _lng = -74.0817;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PassengerTripProvider(),
      child: Scaffold(
        body: Stack(
          children: [
            // 1. El Mapa Mapbox en el fondo
            _buildMapbox(),

            // 2. El botón dual de contexto
            const Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: SafeArea(child: _ToggleWrapper()),
            ),

            // BottomSheet interactivo
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

  Widget _buildMapbox() {
    return CustomMapMapbox(
      key: _mapKey,
      initialLat: _lat,
      initialLng: _lng,
      onMapCreated: (controller) {

        // Prueba: Colocar marcador en ubicación inicial al cargar
        _setInitialMarker();
      },
    );
  }

  void _setInitialMarker() {
    // Usamos el GlobalKey para acceder a los métodos del widget core
    _mapKey.currentState?.addMarker(
      lat: _lat,
      lng: _lng,
      // Nota: Para que el icono aparezca en v2.x, 
      // Mapbox suele requerir una imagen cargada o usar circleAnnotation.
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
