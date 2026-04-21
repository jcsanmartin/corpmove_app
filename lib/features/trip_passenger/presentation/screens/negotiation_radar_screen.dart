import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/map_placeholder.dart';

class NegotiationRadarScreen extends StatefulWidget {
  final bool isCorporateMode;
  final double techoCobertura;

  const NegotiationRadarScreen({
    super.key,
    required this.isCorporateMode,
    required this.techoCobertura,
  });

  @override
  State<NegotiationRadarScreen> createState() => _NegotiationRadarScreenState();
}

class _NegotiationRadarScreenState extends State<NegotiationRadarScreen> {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Simulamos que encuentra conductores después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scaffoldLight,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // Mapa en el fondo ocupando la mitad superior/completa
          const Positioned.fill(child: MapPlaceholder()),

          // Botón de regreso flotante
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 12),
              child: GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 28),
                ),
              ),
            ),
          ),

          // Contenido inferior (Buscando o Lista de Ofertas)
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: double.infinity,
              height:
                  _isLoading ? 220 : MediaQuery.of(context).size.height * 0.65,
              decoration: AppDecorations.bottomSheet,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Grabber
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading) ...[
                    // Estado de Búsqueda
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.accentLime,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Buscando Conductor...',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enviando tu oferta a los más cercanos',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Lista de Ofertas
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ofertas recibidas',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentLime.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '3 cercanos',
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          _buildOfferCard(
                            context: context,
                            driverName: 'Hugo Solano',
                            rating: 5.0,
                            vehicle: 'Nissan Versa 2018',
                            arrival: '2 min',
                            offerAmount: 4.25,
                            isRecommended: true,
                            isCorporateMode: widget.isCorporateMode,
                            techoCobertura: widget.techoCobertura,
                          ),
                          const SizedBox(height: 16),
                          _buildOfferCard(
                            context: context,
                            driverName: 'Ana Pérez',
                            rating: 4.8,
                            vehicle: 'Renault Logan',
                            arrival: '5 min',
                            offerAmount: 5.00,
                            isCorporateMode: widget.isCorporateMode,
                            techoCobertura: widget.techoCobertura,
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceLight,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.cardLight,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.accentLime,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.surfaceLight,
                    child: Icon(Icons.person_rounded,
                        size: 36, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isCorporateMode ? 'Empleado CorpMove' : 'Usuario',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'correo@ejemplo.com',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            title: Text('Volver al inicio',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pop(context); // Go back to Home
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard({
    required BuildContext context,
    required String driverName,
    required double rating,
    required String vehicle,
    required String arrival,
    required double offerAmount,
    required bool isCorporateMode,
    required double techoCobertura,
    bool isRecommended = false,
  }) {
    return Container(
      decoration: AppDecorations.cardElevated,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                // Foto conductor
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            driverName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.accentLime, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toString(),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.surfaceLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.directions_car_rounded,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            vehicle,
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.timer_rounded,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Llegada aprox. $arrival',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sección Oferta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contra ofertó',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '\$${offerAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),

                // Botones
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: AppColors.borderAccent),
                      ),
                      child: Text(
                        'Contra Oferta',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Viaje aceptado')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentLime,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Aceptar',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textOnAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
