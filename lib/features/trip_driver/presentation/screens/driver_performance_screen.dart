import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/trip_driver/presentation/screens/driver_home_screen.dart';

class DriverPerformanceScreen extends StatelessWidget {
  const DriverPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: Text(
          'Mi Rendimiento',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.scaffoldLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de Calificación
            _buildRatingHeader(),
            const SizedBox(height: 24),

            // Estadísticas de Operación
            Text(
              'Estadísticas de Aceptación',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildOperationStats(),
            const SizedBox(height: 32),

            // Sección de Comentarios
            Text(
              'Lo que dicen los pasajeros',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFeedbackList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(Icons.star_rounded, color: Colors.orange, size: 60),
          Text(
            '4.85',
            style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.w900),
          ),
          Text(
            'Calificación promedio',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleStat('1.2k', 'Viajes Totales'),
              _buildSimpleStat('98%', 'Viajes 5 estrellas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildOperationStats() {
    return Column(
      children: [
        _buildProgressIndicator('Tasa de Aceptación', 0.92, AppColors.success),
        const SizedBox(height: 20),
        _buildProgressIndicator('Tasa de Cancelación', 0.05, AppColors.error),
      ],
    );
  }

  Widget _buildProgressIndicator(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackList() {
    final reviews = [
      {'comment': 'Excelente servicio, muy puntual.', 'stars': 5},
      {'comment': 'El vehículo estaba muy limpio.', 'stars': 5},
      {'comment': 'Conduce con mucha precaución.', 'stars': 4},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (i) => Icon(
                  Icons.star_rounded, 
                  size: 16, 
                  color: i < (reviews[index]['stars'] as int) ? Colors.orange : Colors.grey.shade300
                )),
              ),
              const SizedBox(height: 8),
              Text(
                '"${reviews[index]['comment']}"',
                style: GoogleFonts.inter(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }
}