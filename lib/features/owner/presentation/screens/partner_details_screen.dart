import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/owner/presentation/screens/owner_dashboard_screen.dart';

class PartnerDetailsScreen extends StatefulWidget {
  final String partnerName;
  final String partnerEmail;
  final bool initialStatus;

  const PartnerDetailsScreen({
    super.key,
    required this.partnerName,
    required this.partnerEmail,
    this.initialStatus = true,
  });

  @override
  State<PartnerDetailsScreen> createState() => _PartnerDetailsScreenState();
}

class _PartnerDetailsScreenState extends State<PartnerDetailsScreen> {
  late bool isActive;
  double platformCommission = 10.0;

  @override
  void initState() {
    super.initState();
    isActive = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: Text(
          'Detalles del Socio',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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
            // Card de Perfil Principal
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Métricas del Socio
            Text(
              'Rendimiento Comercial',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem('Empleados', '142', Icons.people_outline),
                const SizedBox(width: 16),
                _buildStatItem('Viajes Mes', '850', Icons.local_taxi_outlined),
              ],
            ),
            const SizedBox(height: 24),

            // Configuración del Convenio
            Text(
              'Configuración del Convenio',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildConfigSection(),
            const SizedBox(height: 32),

            // Historial de Actividad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Actividad Reciente',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Ver reportes'),
                ),
              ],
            ),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.borderSubtle,
            child: const Icon(Icons.business_rounded, size: 40, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partnerName,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.partnerEmail,
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Socio Activo' : 'Cuenta Suspendida',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Column(
      children: [
        SwitchListTile(
          title: Text('Estado del servicio', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          subtitle: const Text('Habilita o deshabilita el acceso a viajes corporativos'),
          value: isActive,
          activeColor: AppColors.success,
          onChanged: (val) {
            setState(() => isActive = val);
          },
        ),
        ListTile(
          title: Text('Comisión de plataforma', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          subtitle: const Text('Porcentaje cobrado por cada viaje realizado'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${platformCommission.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          onTap: () {
            // Lógica para editar comisión
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history),
          title: Text('Facturación Semanal #${index + 24}'),
          subtitle: const Text('Procesado el 12 de Octubre'),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }
}