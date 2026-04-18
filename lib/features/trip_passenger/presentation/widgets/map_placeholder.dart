import 'package:flutter/material.dart';

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade300,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
        child: Stack(
          children: [
            // Marcadores simulados con animación de pulso
            Positioned(
              top: 120,
              left: 60,
              child: _MapPin(color: Colors.red.shade400, label: 'Oficina'),
            ),
            Positioned(
              top: 280,
              right: 70,
              child: _MapPin(color: Colors.blue.shade400, label: 'Casa'),
            ),
            Positioned(
              bottom: 200,
              left: 150,
              child: _MapPin(color: Colors.green.shade400, label: 'Destino'),
            ),
            // Indicador de ubicación actual (estilo InDriver)
            const Center(
              child: Icon(
                Icons.my_location,
                size: 32,
                color: Color(0xFF1A237E),
                shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
              ),
            ),
            // Overlay sutil para dar profundidad
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final String label;

  const _MapPin({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 18),
        ),
        Container(
          width: 2,
          height: 16,
          color: color,
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400.withOpacity(0.3)
      ..strokeWidth = 1.0;

    const double step = 40.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Líneas principales más gruesas cada 4 cuadros
    final paintMain = Paint()
      ..color = Colors.grey.shade500.withOpacity(0.2)
      ..strokeWidth = 2.0;

    for (double x = 0; x <= size.width; x += step * 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintMain);
    }
    for (double y = 0; y <= size.height; y += step * 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintMain);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}