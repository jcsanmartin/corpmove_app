import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corpmove_app/core/theme/app_theme.dart';

class RoleAssignmentScreen extends StatefulWidget {
  const RoleAssignmentScreen({super.key});

  @override
  State<RoleAssignmentScreen> createState() => _RoleAssignmentScreenState();
}

class _RoleAssignmentScreenState extends State<RoleAssignmentScreen> {
  final List<String> _roles = ['Company Admin', 'Conductor', 'Pasajero Normal', 'Pasajero Corporativo'];

  final Map<String, IconData> _roleIcons = {
    'Company Admin': Icons.admin_panel_settings_rounded,
    'Conductor': Icons.directions_car_filled_rounded,
    'Pasajero Normal': Icons.person_rounded,
    'Pasajero Corporativo': Icons.business_center_rounded,
  };

  final Map<String, Color> _roleColors = {
    'Company Admin': const Color(0xFFFF6B6B),
    'Conductor': const Color(0xFF4ECDC4),
    'Pasajero Normal': const Color(0xFF007AFF),
    'Pasajero Corporativo': const Color(0xFFC8E600),
  };

  final List<Map<String, dynamic>> _users = [
    {'name': 'Carlos Pérez', 'email': 'carlos@gmail.com', 'role': 'Pasajero Normal'},
    {'name': 'Pedro Martínez', 'email': 'pedro@corpmove.com', 'role': 'Company Admin'},
    {'name': 'Andrés Morales', 'email': 'andres@corpmove.com', 'role': 'Conductor'},
    {'name': 'Laura Sánchez', 'email': 'laura@tech.com', 'role': 'Pasajero Corporativo'},
    {'name': 'María López', 'email': 'maria@gmail.com', 'role': 'Pasajero Normal'},
    {'name': 'Felipe Torres', 'email': 'felipe@corpmove.com', 'role': 'Conductor'},
    {'name': 'Sofía Hernández', 'email': 'sofia@corpmove.com', 'role': 'Pasajero Corporativo'},
    {'name': 'Diego Castillo', 'email': 'diego@corpmove.com', 'role': 'Conductor'},
  ];

  String? _filterRole;

  List<Map<String, dynamic>> get _filteredUsers {
    if (_filterRole == null) return _users;
    return _users.where((u) => u['role'] == _filterRole).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: Text('Asignación de Roles', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.scaffoldLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Role filter chips
          Text('Filtrar por Rol', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('Todos', null),
              const SizedBox(width: 8),
              ..._roles.map((r) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _filterChip(r, r),
              )),
            ]),
          ),
          const SizedBox(height: 20),

          // Role summary
          Container(
            decoration: AppDecorations.cardElevated,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Distribución de Roles', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ..._roles.map((role) {
                final count = _users.where((u) => u['role'] == role).length;
                final pct = _users.isEmpty ? 0.0 : count / _users.length;
                final color = _roleColors[role] ?? AppColors.info;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Icon(_roleIcons[role], color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(role, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text('$count', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.borderSubtle,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ])),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 20),

          // User list
          Text('Usuarios (${_filteredUsers.length})', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...List.generate(_filteredUsers.length, (i) => _buildUserRoleCard(_filteredUsers[i], i)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? role) {
    final selected = _filterRole == role;
    final color = role != null ? (_roleColors[role] ?? AppColors.info) : AppColors.accentLime;
    return GestureDetector(
      onTap: () => setState(() => _filterRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.borderSubtle),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? color : AppColors.textMuted)),
      ),
    );
  }

  Widget _buildUserRoleCard(Map<String, dynamic> user, int index) {
    final role = user['role'] as String;
    final color = _roleColors[role] ?? AppColors.info;
    final icon = _roleIcons[role] ?? Icons.person;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDecorations.card,
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRoleChangeDialog(user),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user['name'], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(user['email'], style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(role, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showRoleChangeDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'];
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: AppDecorations.bottomSheet,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)))),
            Text('Cambiar Rol', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('${user['name']} — ${user['email']}', style: GoogleFonts.inter(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            ..._roles.map((role) {
              final isSelected = selectedRole == role;
              final color = _roleColors[role] ?? AppColors.info;
              final icon = _roleIcons[role] ?? Icons.person;
              return GestureDetector(
                onTap: () => setModalState(() => selectedRole = role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? color : AppColors.borderSubtle, width: isSelected ? 2 : 1),
                  ),
                  child: Row(children: [
                    Icon(icon, color: isSelected ? color : AppColors.textMuted),
                    const SizedBox(width: 14),
                    Expanded(child: Text(role, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isSelected ? color : AppColors.textPrimary))),
                    if (isSelected) Icon(Icons.check_circle_rounded, color: color),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => user['role'] = selectedRole);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Rol actualizado a "$selectedRole"')));
              },
              child: const Text('Guardar Cambios'),
            ),
          ]),
        ),
      ),
    );
  }
}
