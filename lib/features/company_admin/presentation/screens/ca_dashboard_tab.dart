import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/admin/application/admin_provider.dart';

class CaDashboardTab extends StatefulWidget {
  final AdminProvider provider;
  const CaDashboardTab({super.key, required this.provider});

  @override
  State<CaDashboardTab> createState() => _CaDashboardTabState();
}

class _CaDashboardTabState extends State<CaDashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.provider.loadCompanyTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final company = p.companyData;
    final companyName = company?['company_name'] ?? 'Mi Empresa';
    final totalEmployees = p.employees.length;
    final active = p.activeEmployeesCount;
    final pending = p.pendingEmployeesCount;
    final inactive = p.inactiveEmployeesCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // ── Header bienvenida ──
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accentLime.withOpacity(0.85), const Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.accentLime.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Panel Corporativo', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(companyName, style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text('$totalEmployees empleados registrados', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.business_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Tarjetas métricas ──
        Text('Resumen de Empleados', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('Activos', active, AppColors.success, Icons.check_circle_outline_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('Pendientes', pending, AppColors.warning, Icons.hourglass_empty_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('Inactivos', inactive, AppColors.textMuted, Icons.cancel_outlined)),
          ],
        ),
        const SizedBox(height: 24),

        // ── Métricas de viajes ──
        Text('Viajes Corporativos', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('Total viajes', p.companyTrips.length, AppColors.info, Icons.directions_car_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('Completados', p.completedTripsCount, AppColors.accentLime, Icons.done_all_rounded)),
          ],
        ),
        const SizedBox(height: 8),
        _spendCard(p.totalSpent),
        const SizedBox(height: 24),

        // ── Gráfico de barras semanal ──
        _buildWeeklyChart(p),
        const SizedBox(height: 24),

        // ── Convenio rápido ──
        _buildConvenioSummary(company),
        const SizedBox(height: 24),

        // ── Últimos viajes ──
        if (p.companyTrips.isNotEmpty) _buildRecentTrips(p),
      ],
    );
  }

  Widget _metricCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text('$value', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _spendCard(double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.accentLime.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.payments_rounded, color: AppColors.accentLime),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gasto corporativo total', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
              Text('\$${total.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(AdminProvider p) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final data = p.tripsPerDay;
    final maxVal = data.values.fold<int>(1, (a, b) => b > a ? b : a);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Viajes esta semana', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Últimos 7 días', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((d) {
                final count = data[d] ?? 0;
                final barH = maxVal > 0 ? (count / maxVal) * 100.0 : 0.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (count > 0) Text('$count', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentLime)),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      width: 28,
                      height: barH > 0 ? barH : 4,
                      decoration: BoxDecoration(
                        color: barH > 0 ? AppColors.accentLime : AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(d, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvenioSummary(Map<String, dynamic>? company) {
    if (company == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.verified_rounded, color: AppColors.accentLime, size: 18),
            const SizedBox(width: 8),
            Text('Convenio Activo', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 16),
          _convenioRow(Icons.attach_money_rounded, 'Techo por viaje', '\$${company['corporate_limit'] ?? 0}'),
          const Divider(color: AppColors.borderSubtle, height: 20),
          _convenioRow(Icons.directions_rounded, 'Viajes diarios', '${company['daily_trips_limit'] ?? 0} por empleado'),
        ],
      ),
    );
  }

  Widget _convenioRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13))),
      Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13)),
    ]);
  }

  Widget _buildRecentTrips(AdminProvider p) {
    final recent = p.companyTrips.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actividad Reciente', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.borderSubtle, height: 1),
            itemBuilder: (_, i) {
              final t = recent[i];
              final dest = t['destination_text'] as String? ?? 'Destino';
              final cost = (t['cost'] as num?)?.toDouble() ?? 0;
              final status = t['status'] as String? ?? '';
              final statusColor = (status == 'completado' || status == 'finalizado') ? AppColors.success : AppColors.warning;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.accentLime.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.directions_car_rounded, size: 18, color: AppColors.accentLime),
                ),
                title: Text(dest, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(status, style: GoogleFonts.inter(fontSize: 11, color: statusColor)),
                trailing: Text('\$${cost.toStringAsFixed(0)}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.accentLime, fontSize: 14)),
              );
            },
          ),
        ),
      ],
    );
  }
}
