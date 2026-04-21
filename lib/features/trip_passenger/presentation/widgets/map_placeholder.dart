import 'dart:math';
import 'package:flutter/material.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';

class MapPlaceholder extends StatefulWidget {
  const MapPlaceholder({super.key});

  @override
  State<MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<MapPlaceholder>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E), // Dark map base
      child: CustomPaint(
        painter: _DarkStreetPainter(),
        child: Stack(
          children: [
            // Gradient overlay bottom (para que las cards floten bien)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 220,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.scaffoldLight,
                    ],
                  ),
                ),
              ),
            ),

            // Gradient overlay top (para el header)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.scaffoldLight,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Pin de destino (amarillo/lime)
            const Positioned(
              top: 180,
              right: 90,
              child: _MapPin(
                color: AppColors.accentLime,
                isOrigin: false,
              ),
            ),

            // Ruta animada
            Positioned.fill(
              child: CustomPaint(
                painter: _RoutePainter(
                  progress: _pulseController.value,
                ),
              ),
            ),

            // Indicador de ubicación actual con pulso
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulso externo
                      Container(
                        width: 56 * _pulseAnimation.value,
                        height: 56 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppColors.accentLime.withOpacity(0.12),
                        ),
                      ),
                      // Pulso interno
                      Container(
                        width: 32 * _pulseAnimation.value,
                        height: 32 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppColors.accentLime.withOpacity(0.2),
                        ),
                      ),
                      // Pin central
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentLime,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentLime,
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
  final bool isOrigin;

  const _MapPin({required this.color, required this.isOrigin});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            isOrigin ? Icons.my_location : Icons.location_on,
            color: AppColors.textOnAccent,
            size: 18,
          ),
        ),
        Container(
          width: 2,
          height: 12,
          color: color.withOpacity(0.7),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}

/// Pintor de calles estilo mapa oscuro (tipo Uber/InDriver)
class _DarkStreetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintMajor = Paint()
      ..color = const Color(0xFF252540)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final paintMinor = Paint()
      ..color = const Color(0xFF1E1E35)
      ..strokeWidth = 4.0;

    final paintBlock = Paint()..color = const Color(0xFF161628);

    // Bloques de manzanas
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 8; j++) {
        final rect = Rect.fromLTWH(
          i * (size.width / 4) + 12,
          j * (size.height / 7) + 8,
          size.width / 4 - 24,
          size.height / 7 - 16,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paintBlock,
        );
      }
    }

    // Calles principales horizontales
    const double colStep = 80.0;
    for (double y = colStep; y < size.height; y += colStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintMajor);
    }

    // Calles principales verticales
    for (double x = colStep; x < size.width; x += colStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintMajor);
    }

    // Calles secundarias
    const double minorStep = 40.0;
    for (double y = minorStep; y < size.height; y += colStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintMinor);
    }
    for (double x = minorStep; x < size.width; x += colStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintMinor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dibuja una ruta desde el centro hacia el pin de destino
class _RoutePainter extends CustomPainter {
  final double progress;

  _RoutePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentLime.withOpacity(0.8)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final start = Offset(size.width / 2, size.height / 2);
    final end = Offset(size.width - 90, size.height * 0.28);
    final cp1 = Offset(size.width / 2 + 60, size.height * 0.38);

    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(cp1.dx, cp1.dy, end.dx, end.dy);

    // Dibuja ruta con dash
    final pathMetrics = path.computeMetrics().first;
    const dashLength = 12.0;
    const gapLength = 8.0;
    double distance = 0.0;

    while (distance < pathMetrics.length) {
      final extractPath = pathMetrics.extractPath(
        distance,
        min(distance + dashLength, pathMetrics.length),
      );
      canvas.drawPath(extractPath, paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => true;
}