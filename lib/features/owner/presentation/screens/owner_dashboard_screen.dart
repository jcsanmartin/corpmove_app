import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/owner/presentation/screens/partner_details_screen.dart';
import 'package:corpmove_app/features/owner/presentation/screens/manage_company_screen.dart';
import 'package:corpmove_app/features/owner/presentation/screens/manage_users_screen.dart';
import 'package:corpmove_app/features/owner/presentation/screens/manage_drivers_screen.dart';
import 'package:corpmove_app/features/owner/presentation/screens/role_assignment_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel del Dueño - CorpMove',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        backgroundColor: AppColors.scaffoldLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
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
                child: const Icon(Icons.menu_rounded,
                    color: AppColors.textPrimary, size: 24),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones globales')),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: AppDecorations.cardElevated,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Métricas Globales',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Empresas', '12'),
                      _buildMetric('Usuarios', '1,250'),
                      _buildMetric('Conductores', '85'),
                      _buildMetric('Viajes Hoy', '342'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Tarjetas de Navegación ---
          Text(
            'Gestión Rápida',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.05,
            children: [
              _buildNavCard(
                context,
                icon: Icons.business_rounded,
                label: 'Empresas',
                subtitle: 'Convenios corporativos',
                color: const Color(0xFF4ECDC4),
                destination: const ManageCompanyScreen(),
              ),
              _buildNavCard(
                context,
                icon: Icons.directions_car_filled_rounded,
                label: 'Conductores',
                subtitle: 'Gestión de conductores',
                color: const Color(0xFFFF6B6B),
                destination: const ManageDriversScreen(),
              ),
              _buildNavCard(
                context,
                icon: Icons.people_rounded,
                label: 'Usuarios',
                subtitle: 'Normales y corporativos',
                color: AppColors.info,
                destination: const ManageUsersScreen(),
              ),
              _buildNavCard(
                context,
                icon: Icons.admin_panel_settings_rounded,
                label: 'Roles',
                subtitle: 'Asignación de roles',
                color: AppColors.accentLime,
                destination: const RoleAssignmentScreen(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Empresas Afiliadas ---
          Container(
            decoration: AppDecorations.cardElevated,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Empresas Afiliadas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildCompanyTile(
                      context, 'CorpMove S.A.', 'admin@corpmove.com', true),
                  _buildCompanyTile(
                      context, 'Tech Solutions', 'admin@tech.com', true),
                  _buildCompanyTile(
                      context, 'Logística Express', 'admin@logex.com', false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: AppDecorations.cardElevated,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuración Global',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Modo mantenimiento'),
                    value: false,
                    onChanged: (_) {},
                    activeThumbColor: AppColors.accentLime,
                  ),
                  SwitchListTile(
                    title: const Text('Habilitar registro público'),
                    value: true,
                    onChanged: (_) {},
                    activeThumbColor: AppColors.accentLime,
                  ),
                  ListTile(
                    title: const Text('Comisión por viaje'),
                    trailing: const Text('10%'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tarjeta de Navegación ---
  Widget _buildNavCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Widget destination,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destination),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const Spacer(),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Drawer del Dueño ---
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
                      color: AppColors.accentLime, shape: BoxShape.circle),
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.surfaceLight,
                    child: Icon(Icons.admin_panel_settings_rounded,
                        size: 36, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Dueño - CorpMove',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  'owner@corpmove.com',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Empresas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManageCompanyScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Conductores'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManageDriversScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Usuarios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManageUsersScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Roles'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RoleAssignmentScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración global'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración de la plataforma')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(label, style: GoogleFonts.inter(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildCompanyTile(
      BuildContext context, String name, String email, bool active) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: active
            ? AppColors.success.withOpacity(0.1)
            : AppColors.borderSubtle,
        child: Icon(Icons.business,
            color: active ? AppColors.success : AppColors.textMuted),
      ),
      title: Text(
        name,
        style: GoogleFonts.inter(
            fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        email,
        style: GoogleFonts.inter(color: AppColors.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),

      // ESTO ES LO QUE HACE QUE EL CLIC FUNCIONE:
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartnerDetailsScreen(
              partnerName: name,
              partnerEmail: email,
              initialStatus: active,
            ),
          ),
        );
      },
    );
  }
}
