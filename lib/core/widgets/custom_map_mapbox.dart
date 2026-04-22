import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

class CustomMapMapbox extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final Function(mbx.MapboxMap)? onMapCreated;
  final String styleUri;

  const CustomMapMapbox({
    super.key,
    this.initialLat = 4.6097, // Bogotá por defecto
    this.initialLng = -74.0817,
    this.initialZoom = 14.0,
    this.onMapCreated,
    this.styleUri = mbx.MapboxStyles.DARK,
  });

  @override
  State<CustomMapMapbox> createState() => CustomMapMapboxState();
}

class CustomMapMapboxState extends State<CustomMapMapbox> {
  mbx.MapboxMap? _mapboxMap;
  mbx.PointAnnotationManager? _pointAnnotationManager;

  @override
  Widget build(BuildContext context) {
    return mbx.MapWidget(
      key: const ValueKey("mapbox_map"),
      styleUri: widget.styleUri,
      onMapCreated: (mbx.MapboxMap mapboxMap) async {
        _mapboxMap = mapboxMap;
        
        // Inicializar el gestor de anotaciones (marcadores)
        _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
        
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(mapboxMap);
        }
      },
      cameraOptions: mbx.CameraOptions(
        center: mbx.Point(
          coordinates: mbx.Position(widget.initialLng, widget.initialLat),
        ),
        zoom: widget.initialZoom,
      ),
    );
  }

  /// Método público para añadir un marcador
  /// [iconImage] es el nombre de la imagen que debe estar pre-cargada en el estilo
  /// o un asset registrado.
  Future<void> addMarker({
    required double lat,
    required double lng,
    String? iconImage,
    double iconSize = 1.0,
  }) async {
    if (_pointAnnotationManager == null) return;

    final options = mbx.PointAnnotationOptions(
      geometry: mbx.Point(coordinates: mbx.Position(lng, lat)),
      iconImage: iconImage,
      iconSize: iconSize,
    );
    
    await _pointAnnotationManager!.create(options);
  }

  /// Método público para limpiar marcadores
  Future<void> clearMarkers() async {
    await _pointAnnotationManager?.deleteAll();
  }

  /// Mover la cámara a una posición
  void animateCamera(double lat, double lng, {double? zoom}) {
    _mapboxMap?.flyTo(
      mbx.CameraOptions(
        center: mbx.Point(coordinates: mbx.Position(lng, lat)),
        zoom: zoom,
      ),
      mbx.MapAnimationOptions(duration: 1000),
    );
  }
}
