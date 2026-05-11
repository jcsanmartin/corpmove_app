import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';
import 'package:corpmove_app/features/admin/application/admin_provider.dart';

class CaEmployeesTab extends StatefulWidget {
  final AdminProvider provider;
  const CaEmployeesTab({super.key, required this.provider});

  @override
  State<CaEmployeesTab> createState() => _CaEmployeesTabState();
}

class _CaEmployeesTabState extends State<CaEmployeesTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final all = p.employees.where((e) {
      final name = (e['display_name'] ?? e['name'] ?? '').toString().toLowerCase();
      final email = (e['email'] ?? '').toString().toLowerCase();
      return name.contains(_search.toLowerCase()) || email.contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      body: Column(
        children: [
          // ── Stats ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            color: AppColors.cardLight,
            child: Row(
              children: [
                _statPill('Total', p.employees.length, AppColors.info),
                const SizedBox(width: 8),
                _statPill('Activos', p.activeEmployeesCount, AppColors.success),
                const SizedBox(width: 8),
                _statPill('Pendientes', p.pendingEmployeesCount, AppColors.warning),
                const SizedBox(width: 8),
                _statPill('Inactivos', p.inactiveEmployeesCount, AppColors.textMuted),
              ],
            ),
          ),
          // ── Buscador ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar empleado...',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // ── Lista ──
          Expanded(
            child: all.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.people_outline_rounded, size: 60, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text(_search.isEmpty ? 'No hay empleados registrados' : 'Sin resultados', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: all.length,
                    itemBuilder: (ctx, i) => _buildEmployeeCard(ctx, p, all[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEmployeeDialog(context, p, null),
        backgroundColor: AppColors.accentLime,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.person_add_rounded),
        label: Text('Agregar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _statPill(String label, int val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text('$val', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: color)),
        ]),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, AdminProvider p, Map<String, dynamic> emp) {
    final name = emp['display_name'] ?? emp['name'] ?? 'Sin nombre';
    final email = emp['email'] ?? '';
    final isActive = emp['is_active'] == true || emp['estado_solicitud'] == 'aprobado';
    final uid = (emp['id'] ?? '').toString();
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final estado = emp['estado_solicitud'] as String? ?? 'ninguno';

    Color statusColor;
    String statusLabel;
    switch (estado) {
      case 'aprobado': statusColor = AppColors.success; statusLabel = 'Activo'; break;
      case 'pendiente': statusColor = AppColors.warning; statusLabel = 'Pendiente'; break;
      case 'rechazado': statusColor = AppColors.error; statusLabel = 'Rechazado'; break;
      default: statusColor = isActive ? AppColors.success : AppColors.textMuted;
               statusLabel = isActive ? 'Activo' : 'Inactivo';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: () => _showProfileSheet(context, p, emp),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.accentLime.withOpacity(0.15),
                backgroundImage: emp['photo_url'] != null ? NetworkImage(emp['photo_url'] as String) : null,
                child: emp['photo_url'] == null
                    ? Text(initials, style: GoogleFonts.inter(color: AppColors.accentLime, fontWeight: FontWeight.w800, fontSize: 18))
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15)),
                const SizedBox(height: 2),
                Text(email, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel, style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
              color: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'view') _showProfileSheet(context, p, emp);
                if (val == 'edit') _showEmployeeDialog(context, p, emp);
                if (val == 'toggle') p.toggleEmployeeStatus(uid, isActive);
                if (val == 'delete') _confirmDelete(context, p, uid, name);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'view', child: _menuItem(Icons.visibility_outlined, 'Ver perfil')),
                PopupMenuItem(value: 'edit', child: _menuItem(Icons.edit_outlined, 'Editar')),
                PopupMenuItem(value: 'toggle', child: _menuItem(isActive ? Icons.block_outlined : Icons.check_circle_outline, isActive ? 'Desactivar' : 'Activar')),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'delete', child: _menuItem(Icons.delete_outline, 'Eliminar', color: AppColors.error)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {Color? color}) {
    return Row(children: [
      Icon(icon, size: 18, color: color ?? AppColors.textPrimary),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.inter(color: color ?? AppColors.textPrimary)),
    ]);
  }

  void _showProfileSheet(BuildContext context, AdminProvider p, Map<String, dynamic> emp) {
    final name = emp['display_name'] ?? emp['name'] ?? 'Sin nombre';
    final email = emp['email'] ?? '';
    final phone = emp['phone'] ?? 'No registrado';
    final position = emp['position'] ?? 'No registrado';
    final isActive = emp['is_active'] == true || emp['estado_solicitud'] == 'aprobado';
    final uid = (emp['id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.accentLime.withOpacity(0.15),
            backgroundImage: emp['photo_url'] != null ? NetworkImage(emp['photo_url'] as String) : null,
            child: emp['photo_url'] == null
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: GoogleFonts.inter(color: AppColors.accentLime, fontWeight: FontWeight.w800, fontSize: 28))
                : null,
          ),
          const SizedBox(height: 12),
          Text(name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(email, style: GoogleFonts.inter(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          _profileRow(Icons.phone_outlined, 'Teléfono', phone),
          _profileRow(Icons.work_outline_rounded, 'Cargo', position),
          _profileRow(Icons.circle, 'Estado', isActive ? 'Activo' : 'Inactivo', valueColor: isActive ? AppColors.success : AppColors.textMuted),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () { Navigator.pop(context); _showEmployeeDialog(context, p, emp); },
                icon: const Icon(Icons.edit_outlined),
                label: Text('Editar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentLime, side: const BorderSide(color: AppColors.accentLime), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _confirmDelete(context, p, uid, name); },
                icon: const Icon(Icons.delete_outline),
                label: Text('Eliminar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Text('$label:', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary, fontSize: 13), textAlign: TextAlign.right)),
      ]),
    );
  }

  void _showEmployeeDialog(BuildContext context, AdminProvider p, Map<String, dynamic>? employee) {
    final isEdit = employee != null;
    final nameCtrl = TextEditingController(text: isEdit ? (employee['display_name'] ?? employee['name'] ?? '') : '');
    final emailCtrl = TextEditingController(text: isEdit ? (employee['email'] ?? '') : '');
    final phoneCtrl = TextEditingController(text: isEdit ? (employee['phone'] ?? '') : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? 'Editar Empleado' : 'Agregar Empleado', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(nameCtrl, 'Nombre completo', Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _dialogField(emailCtrl, 'Correo electrónico', Icons.email_outlined, type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _dialogField(phoneCtrl, 'Teléfono (opcional)', Icons.phone_outlined, type: TextInputType.phone),
          if (!isEdit) Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('El empleado podrá vincularse con este correo al registrarse.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final email = emailCtrl.text.trim();
              if (name.isEmpty || email.isEmpty) return;
              if (isEdit) {
                p.updateEmployee((employee['id'] ?? '').toString(), name, email);
              } else {
                p.addEmployee(name, email);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentLime, foregroundColor: AppColors.textOnAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(isEdit ? 'Guardar' : 'Agregar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon, {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.inter(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.cardLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentLime, width: 1.5)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminProvider p, String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar empleado', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('¿Deseas eliminar a $name? Esta acción no se puede deshacer.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () { p.deleteEmployee(uid); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Eliminar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
