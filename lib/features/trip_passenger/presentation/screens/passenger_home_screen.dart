import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/screens/negotiation_radar_screen.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/map_placeholder.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/dual_mode_selector.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/profile_tab.dart';

class PassengerHomeScreen extends StatefulWidget {
  final bool isCorporateEnabled;

  const PassengerHomeScreen({
    super.key,
    required this.isCorporateEnabled,
  });

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  late bool _isCorporateMode;
  final double _techoCobertura = 15000.0;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _isCorporateMode = widget.isCorporateEnabled;
  }

  late final List<Widget> _screens = [
    _buildHomeTab(),
    const _HistoryTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scaffoldLight,
      drawer: _buildDrawer(context),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.surfaceLight,
        elevation: 16,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
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
                  decoration: BoxDecoration(
                    color: AppColors.accentLime,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.surfaceLight,
                    child: Icon(Icons.person_rounded, size: 36, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isCorporateEnabled ? 'Empleado CorpMove' : 'Usuario',
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
            leading: const Icon(Icons.account_circle_rounded, color: AppColors.textPrimary),
            title: Text('Mi cuenta', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: AppColors.textPrimary),
            title: Text('Configuración', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(color: AppColors.borderSubtle),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text('Cerrar sesión', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Stack(
      children: [
        // Mapa al fondo
        const Positioned.fill(child: MapPlaceholder()),

        // Top bar con menú y bienvenida flotante
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menú hamburgesa flotante
                GestureDetector(
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
                const SizedBox(width: 16),
                // Texto de Bienvenida como en la referencia
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido,',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF0F0F0), // Blanco tirando a gris suave
                            shadows: [
                              Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 12),
                            ],
                          ),
                        ),
                        Text(
                          'Carlos',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 12),
                            ],
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

        // Botón Mi ubicación flotante
        Positioned(
          right: 20,
          bottom: widget.isCorporateEnabled ? 280 : 220, // Ajuste para no chocar con el bottom sheet
          child: FloatingActionButton(
            heroTag: 'location',
            backgroundColor: AppColors.surfaceLight,
            foregroundColor: AppColors.textPrimary,
            elevation: 4,
            mini: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Centrando ubicación...')),
              );
            },
            child: const Icon(Icons.my_location_rounded),
          ),
        ),

        // Bottom Sheet "Hacia dónde vas" y "Qué servicio deseas"
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            decoration: AppDecorations.bottomSheet,
            padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

                Text(
                  '¿Hacia a dónde vas?',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Selector de Modo (Personal / Corporativo)
                if (widget.isCorporateEnabled)
                  DualModeSelector(
                    isCorporateMode: _isCorporateMode,
                    onModeChanged: (value) => setState(() => _isCorporateMode = value),
                  ),
                if (!widget.isCorporateEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Modo Personal',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Botón principal "Ofertar" / "Buscar Viaje"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NegotiationRadarScreen(
                            isCorporateMode: widget.isCorporateEnabled && _isCorporateMode,
                            techoCobertura: widget.isCorporateEnabled ? _techoCobertura : 0.0,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLime,
                      foregroundColor: AppColors.textOnAccent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.isCorporateEnabled && _isCorporateMode
                          ? 'Solicitar Viaje Corp'
                          : 'Solicitar Viaje',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                // Aviso de techo de cobertura
                if (widget.isCorporateEnabled && _isCorporateMode) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentLime.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentLime.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.textPrimary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Techo cobertura: \$${_techoCobertura.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Historial de viajes',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Próximamente...',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}