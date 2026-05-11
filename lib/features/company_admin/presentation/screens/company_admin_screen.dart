import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/admin/application/admin_provider.dart';
import 'ca_dashboard_tab.dart';
import 'ca_employees_tab.dart';
import 'ca_reports_tab.dart';

class CompanyAdminScreen extends StatefulWidget {
  const CompanyAdminScreen({super.key});

  @override
  State<CompanyAdminScreen> createState() => _CompanyAdminScreenState();
}

class _CompanyAdminScreenState extends State<CompanyAdminScreen> {
  int _currentIndex = 0;
  // 0: Dashboard, 1: Empleados, 2: Convenio, 3: Reportes, 4: Solicitudes

  static const _navItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
    {'icon': Icons.people_rounded, 'label': 'Empleados'},
    {'icon': Icons.verified_rounded, 'label': 'Convenio'},
    {'icon': Icons.analytics_rounded, 'label': 'Reportes'},
    {'icon': Icons.pending_actions_rounded, 'label': 'Solicitudes'},
  ];

  String _getTitle() {
    switch (_currentIndex) {
      case 0: return 'Panel Corporativo';
      case 1: return 'Empleados';
      case 2: return 'Convenio';
      case 3: return 'Reportes';
      case 4: return 'Solicitudes';
      default: return 'Panel Corporativo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldLight,
        appBar: AppBar(
          title: Text(_getTitle(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 18)),
          backgroundColor: AppColors.scaffoldLight,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: Builder(
            builder: (ctx) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 22),
                ),
              ),
            ),
          ),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.borderSubtle)),
        ),
        drawer: Builder(builder: (ctx) => _buildDrawer(ctx)),
        body: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            _handleSnackBars(context, provider);

            if (provider.state == AdminState.loading && provider.companyData == null) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accentLime));
            }
            if (provider.state == AdminState.noCompany) {
              return _buildNoCompanyView(context, provider);
            }
            if (provider.state == AdminState.error && provider.companyData == null) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error al conectar', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(provider.errorMessage, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
              ]));
            }

            switch (_currentIndex) {
              case 0: return CaDashboardTab(provider: provider);
              case 1: return CaEmployeesTab(provider: provider);
              case 2: return _buildConfigView(context, provider, provider.companyData ?? {});
              case 3: return CaReportsTab(provider: provider);
              case 4: return _buildPendingRequestsView(provider);
              default: return CaDashboardTab(provider: provider);
            }
          },
        ),
      ),
    );
  }

  // ── Drawer ──
  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = (user?.displayName?.isNotEmpty == true) ? user!.displayName! : (user?.email?.split('@').first ?? 'Usuario');
    final userEmail = user?.email ?? '';

    return Drawer(
      backgroundColor: AppColors.surfaceLight,
      child: Column(
        children: [
          // Header con gradiente
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, bottom: 24, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                backgroundImage: _getAvatarImageProvider(user?.photoURL),
                child: user?.photoURL == null ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'A', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)) : null,
              ),
              const SizedBox(height: 12),
              Text(userName, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(userEmail, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('Admin Corporativo', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ..._navItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final selected = _currentIndex == i;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accentLime.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: Icon(item['icon'] as IconData, color: selected ? AppColors.accentLime : AppColors.textMuted, size: 22),
                      title: Text(item['label'] as String, style: GoogleFonts.inter(fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? AppColors.accentLime : AppColors.textSecondary, fontSize: 14)),
                      trailing: selected ? Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.accentLime, borderRadius: BorderRadius.circular(2))) : null,
                      onTap: () { setState(() => _currentIndex = i); Navigator.pop(context); },
                    ),
                  );
                }),
                const Divider(color: AppColors.borderSubtle, indent: 16, endIndent: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                    title: Text('Cerrar sesión', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 14)),
                    onTap: () { Navigator.pop(context); Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false); },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sin empresa ──
  Widget _buildNoCompanyView(BuildContext context, AdminProvider provider) {
    final ctrl = TextEditingController();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderSubtle)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)]), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.business_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Bienvenido al Panel Corporativo', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Registra tu empresa para comenzar a gestionar los beneficios de tus empleados.', style: GoogleFonts.inter(color: AppColors.textMuted, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            TextField(
              controller: ctrl,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Nombre de la empresa',
                labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.apartment_rounded, color: AppColors.textMuted),
                filled: true, fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentLime, width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { final n = ctrl.text.trim(); if (n.isNotEmpty) provider.createCompany(n); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentLime, foregroundColor: AppColors.textOnAccent, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Registrar Empresa', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Configuración de convenio ──
  Widget _buildConfigView(BuildContext context, AdminProvider provider, Map<String, dynamic> company) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF388E3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Configuración de Convenio', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              Text('Ajusta los parámetros del acuerdo corporativo', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
          child: Column(children: [
            _buildConfigItem(context, provider, 'Techo por viaje', '\$${company['corporate_limit'] ?? 0}', 'corporate_limit', true),
            const Divider(color: AppColors.borderSubtle, height: 1),
            _buildConfigItem(context, provider, 'Viajes diarios máximos', '${company['daily_trips_limit'] ?? 0}', 'daily_trips_limit', true),
            const Divider(color: AppColors.borderSubtle, height: 1),
            _buildConfigItem(context, provider, 'Horario permitido', company['allowed_schedules'] is List ? (company['allowed_schedules'] as List).join(', ') : (company['allowed_schedules'] ?? 'Sin definir').toString(), 'allowed_schedules', false),
          ]),
        ),
      ],
    );
  }

  Widget _buildConfigItem(BuildContext ctx, AdminProvider p, String label, String value, String fieldKey, bool isNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ])),
        TextButton.icon(
          onPressed: () => _showEditDialog(ctx, p, label, value, fieldKey, isNumber),
          icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.accentLime),
          label: Text('Editar', style: GoogleFonts.inter(color: AppColors.accentLime, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ]),
    );
  }

  void _showEditDialog(BuildContext ctx, AdminProvider p, String title, String currentValue, String fieldKey, bool isNumber) {
    final ctrl = TextEditingController(text: currentValue.replaceAll('\$', '').replaceAll(',', ''));
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar $title', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true, fillColor: AppColors.cardLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentLime, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              dynamic v;
              if (isNumber) {
                v = fieldKey == 'daily_trips_limit' ? (int.tryParse(ctrl.text) ?? 0) : (double.tryParse(ctrl.text) ?? 0.0);
              } else {
                v = fieldKey == 'allowed_schedules' ? [ctrl.text] : ctrl.text;
              }
              await p.updateConfigField(fieldKey, v);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentLime, foregroundColor: AppColors.textOnAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Solicitudes Pendientes ──
  Widget _buildPendingRequestsView(AdminProvider p) {
    final pending = p.employees.where((e) => e['estado_solicitud'] == 'pendiente').toList();
    return pending.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.inbox_rounded, size: 60, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Sin solicitudes pendientes', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pending.length,
            itemBuilder: (_, i) {
              final data = pending[i];
              final docId = (data['id'] ?? '').toString();
              final nombre = data['full_name'] ?? data['display_name'] ?? data['name'] ?? 'Sin nombre';
              final email = data['email'] ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.warning.withOpacity(0.15),
                      backgroundImage: _getAvatarImageProvider(data['photo_url']),
                      child: data['photo_url'] == null ? Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U', style: GoogleFonts.inter(color: AppColors.warning, fontWeight: FontWeight.w800)) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nombre, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15)),
                      Text(email, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('Pendiente', style: GoogleFonts.inter(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton.icon(
                      onPressed: () => p.rejectRequest(docId),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text('Rechazar', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => p.approveRequest(docId),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text('Aprobar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    ),
                  ]),
                ]),
              );
            },
          );
  }

  // ── Helpers ──
  ImageProvider? _getAvatarImageProvider(dynamic url) {
    if (url == null || url.toString().isEmpty) return null;
    if (url.toString().startsWith('data:image')) {
      try { return MemoryImage(base64Decode(url.toString().split(',').last)); } catch (_) { return null; }
    }
    return NetworkImage(url.toString());
  }

  void _handleSnackBars(BuildContext context, AdminProvider provider) {
    if (provider.state == AdminState.success || provider.state == AdminState.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.state == AdminState.success ? 'Cambio guardado exitosamente.' : 'Error: ${provider.errorMessage}'),
          backgroundColor: provider.state == AdminState.success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
        provider.clearState();
      });
    }
  }
}
