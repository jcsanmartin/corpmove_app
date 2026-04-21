import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:corpmove_app/features/admin/application/admin_provider.dart';

class CompanyAdminScreen extends StatefulWidget {
  const CompanyAdminScreen({super.key});

  @override
  State<CompanyAdminScreen> createState() => _CompanyAdminScreenState();
}

class _CompanyAdminScreenState extends State<CompanyAdminScreen> {
  int _currentIndex =
      0; // 0: Dashboard, 1: Empleados, 2: Configuración, 3: Reportes

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Slate 50
        appBar: AppBar(
          title: Text('Panel Corporativo',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF0F172A), // Slate 900
          foregroundColor: Colors.white,
          actions: [
            Builder(builder: (context) {
              return IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sin notificaciones nuevas')),
                  );
                },
              );
            }),
          ],
        ),
        drawer: Builder(
          builder: (context) => _buildDrawer(context),
        ),
        body: Consumer<AdminProvider>(
          builder: (context, provider, child) {
            // Manejar SnackBars para éxito/error global
            _handleSnackBars(context, provider);

            if (provider.state == AdminState.loading &&
                provider.companyData == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.state == AdminState.noCompany) {
              return _buildNoCompanyView(context, provider);
            }

            if (provider.state == AdminState.error &&
                provider.companyData == null) {
              return Center(child: Text('Error: ${provider.errorMessage}'));
            }

            final company = provider.companyData;
            if (company == null) {
              return const Center(child: Text('Cargando configuración...'));
            }

            // Alternar vista según el índice del Drawer
            switch (_currentIndex) {
              case 0:
                return _buildDashboardView(provider);
              case 1:
                return _buildEmployeesView(provider);
              case 2:
                return _buildConfigView(context, provider, company);
              case 3:
                return _buildReportsView(context);
              case 4:
                return _buildPendingRequestsView(provider);
              default:
                return _buildDashboardView(provider);
            }
          },
        ),
      ),
    );
  }

  // ==========================================
  // VISTAS PRINCIPALES
  // ==========================================

  Widget _buildDashboardView(AdminProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildEnterpriseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de Empleados',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Activos', '${provider.activeEmployeesCount}',
                      Colors.green),
                  _buildStat('Pendientes', '${provider.pendingEmployeesCount}',
                      Colors.orange),
                  _buildStat('Inactivos', '${provider.inactiveEmployeesCount}',
                      Colors.grey),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildEnterpriseCard(
          child: Text(
            'Bienvenido al panel central de administración. Desde el menú lateral puedes gestionar a tus empleados, modificar el convenio o descargar reportes de consumo.',
            style: GoogleFonts.inter(
                color: const Color(0xFF64748B), fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeesView(AdminProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestión de Empleados',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A)),
            ),
            ElevatedButton.icon(
              onPressed: () => _showEmployeeDialog(context, provider, null),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), // Blue 600
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEnterpriseCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.employees.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No hay empleados registrados en esta empresa.',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.employees.length,
                  itemBuilder: (context, index) {
                    final emp = provider.employees[index];
                    final isActive = emp['is_active'] == true ||
                        emp['estado_solicitud'] == 'aprobado';
                    return _buildEmployeeTile(
                      emp['name'] ?? emp['display_name'] ?? 'Usuario sin nombre',
                      emp['email'] ?? 'Sin correo',
                      isActive,
                      provider,
                      (emp['id'] ?? '').toString(),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigView(BuildContext context, AdminProvider provider,
      Map<String, dynamic> company) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildEnterpriseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración de Convenio',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 24),
              _buildConfigItem(
                context,
                provider,
                'Techo por viaje',
                '\$${company['corporate_limit'] ?? 0}',
                'corporate_limit',
                true,
              ),
              const Divider(),
              _buildConfigItem(
                context,
                provider,
                'Viajes diarios máximos',
                '${company['daily_trips_limit'] ?? 0}',
                'daily_trips_limit',
                true,
              ),
              const Divider(),
              _buildConfigItem(
                context,
                provider,
                'Horario permitido',
                company['allowed_schedules'] is List
                    ? company['allowed_schedules'].join(', ')
                    : (company['allowed_schedules'] ?? 'Sin definir')
                        .toString(),
                'allowed_schedules',
                false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildEnterpriseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.analytics, size: 60, color: Color(0xFF0F172A)),
              const SizedBox(height: 24),
              Text(
                'Reportes de Facturación Mensual',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              Text(
                'Descarga el detalle de todos los viajes corporativos realizados por tus empleados durante el último mes de facturación.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: const Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generando archivo CSV...'),
                        backgroundColor: Colors.indigo,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2563EB), // Blue 600
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // COMPONENTES SECUNDARIOS Y MÉTODOS
  // ==========================================

  Widget _buildEnterpriseCard(
      {required Widget child,
      EdgeInsetsGeometry padding = const EdgeInsets.all(24)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  ImageProvider? _getAvatarImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  // ==========================================
  // VISTA DE SOLICITUDES PENDIENTES
  // ==========================================

  Widget _buildPendingRequestsView(AdminProvider provider) {
    final pendingDocs = provider.employees
        .where((e) => e['estado_solicitud'] == 'pendiente')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Solicitudes Corporativas Pendientes',
          style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        if (pendingDocs.isEmpty)
          _buildEnterpriseCard(
            child: Column(
              children: [
                const Icon(Icons.inbox, size: 60, color: Color(0xFF64748B)),
                const SizedBox(height: 16),
                Text('No hay solicitudes pendientes',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF64748B), fontSize: 16)),
              ],
            ),
          )
        else
          ...pendingDocs.map((data) {
            final docId = (data['id'] ?? '').toString();
            final nombre = data['full_name'] ??
                data['displayName'] ??
                data['name'] ??
                'Sin nombre';
            final email = data['email'] ?? '';
            final notas = data['notas'] ?? '';
            final photoUrl = data['photo_url'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEnterpriseCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: _getAvatarImageProvider(photoUrl),
                          backgroundColor: const Color(0xFFE2E8F0),
                          child: photoUrl == null
                              ? Text(
                                  nombre.isNotEmpty
                                      ? nombre[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nombre,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: const Color(0xFF0F172A))),
                              Text(email,
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text('EMPLOYEE',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB))),
                          backgroundColor:
                              const Color(0xFF2563EB).withOpacity(0.1),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (notas.isNotEmpty)
                      Text('Notas: $notas',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF334155))),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => provider.rejectRequest(docId),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: Text('Rechazar',
                              style: GoogleFonts.inter(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => provider.approveRequest(docId),
                          icon: const Icon(Icons.check),
                          label: Text('Aprobar',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  // ==========================================
  // COMPONENTES SECUNDARIOS Y MÉTODOS
  // ==========================================

  Widget _buildNoCompanyView(BuildContext context, AdminProvider provider) {
    final TextEditingController companyController = TextEditingController();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildEnterpriseCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business, size: 64, color: Color(0xFF0F172A)),
              const SizedBox(height: 24),
              Text(
                'Bienvenido al Panel de Empresa',
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Para comenzar a gestionar los beneficios corporativos de tus empleados, primero debes registrar tu empresa en la plataforma.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: const Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: companyController,
                style: GoogleFonts.inter(color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Nombre de la empresa',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF2563EB), width: 1.5)),
                  prefixIcon:
                      const Icon(Icons.apartment, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = companyController.text.trim();
                    if (name.isNotEmpty) {
                      provider.createCompany(name);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Por favor, ingresa un nombre válido')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2563EB), // Blue 600
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Registrar Empresa',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSnackBars(BuildContext context, AdminProvider provider) {
    if (provider.state == AdminState.success ||
        provider.state == AdminState.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (provider.state == AdminState.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cambio guardado exitosamente.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (provider.state == AdminState.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${provider.errorMessage}'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        provider
            .clearState(); // Limpiamos el estado para que no vuelva a saltar
      });
    }
  }

  // 🔥 Drawer ADMIN COMPLETO ACTUALIZADO
  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName =
        (user?.displayName != null && user!.displayName!.isNotEmpty)
            ? user.displayName!
            : (user?.email?.split('@').first ?? 'Usuario');
    final userEmail = user?.email ?? 'correo@ejemplo.com';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                bottom: 24,
                left: 16,
                right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), // Slate 900
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: _getAvatarImageProvider(user?.photoURL),
                  child: user?.photoURL == null
                      ? const Icon(Icons.person,
                          size: 40, color: Color(0xFF0F172A))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard,
                color:
                    _currentIndex == 0 ? const Color(0xFF1A237E) : Colors.grey),
            title: Text('Dashboard',
                style: TextStyle(
                    fontWeight: _currentIndex == 0
                        ? FontWeight.bold
                        : FontWeight.normal)),
            selected: _currentIndex == 0,
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context); // Cierra drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.people,
                color:
                    _currentIndex == 1 ? const Color(0xFF1A237E) : Colors.grey),
            title: Text('Empleados',
                style: TextStyle(
                    fontWeight: _currentIndex == 1
                        ? FontWeight.bold
                        : FontWeight.normal)),
            selected: _currentIndex == 1,
            onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings,
                color:
                    _currentIndex == 2 ? const Color(0xFF1A237E) : Colors.grey),
            title: Text('Configuración de convenio',
                style: TextStyle(
                    fontWeight: _currentIndex == 2
                        ? FontWeight.bold
                        : FontWeight.normal)),
            selected: _currentIndex == 2,
            onTap: () {
              setState(() => _currentIndex = 2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.pending_actions,
                color:
                    _currentIndex == 4 ? const Color(0xFF1A237E) : Colors.grey),
            title: Text('Solicitudes pendientes',
                style: TextStyle(
                    fontWeight: _currentIndex == 4
                        ? FontWeight.bold
                        : FontWeight.normal)),
            selected: _currentIndex == 4,
            onTap: () {
              setState(() => _currentIndex = 4);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.bar_chart,
                color:
                    _currentIndex == 3 ? const Color(0xFF1A237E) : Colors.grey),
            title: Text('Reportes',
                style: TextStyle(
                    fontWeight: _currentIndex == 3
                        ? FontWeight.bold
                        : FontWeight.normal)),
            selected: _currentIndex == 3,
            onTap: () {
              setState(() => _currentIndex = 3);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
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

  // 📊 Stats Card Element
  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // ⚙️ Config items Element
  Widget _buildConfigItem(BuildContext context, AdminProvider provider,
      String label, String value, String fieldKey, bool isNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              flex: 2,
              child: Text(label, style: const TextStyle(fontSize: 16))),
          Expanded(
              flex: 2,
              child: Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              )),
          TextButton(
            onPressed: () => _showEditDialog(
                context, provider, label, value, fieldKey, isNumber),
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  // Dialog para editar
  void _showEditDialog(BuildContext context, AdminProvider provider,
      String title, String currentValue, String fieldKey, bool isNumber) {
    final TextEditingController editController = TextEditingController(
        text: currentValue.replaceAll('\$', '').replaceAll(',', ''));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Editar $title',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: editController,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                dynamic newValue;
                if (isNumber) {
                  newValue = double.tryParse(editController.text) ?? 0.0;
                } else {
                  if (fieldKey == 'allowed_schedules') {
                    newValue = [editController.text];
                  } else {
                    newValue = editController.text;
                  }
                }
                await provider.updateConfigField(fieldKey, newValue);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // 👤 Empleado Tile
  Widget _buildEmployeeTile(String name, String email, bool isActive,
      AdminProvider provider, String uid) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isActive ? Colors.green.shade100 : Colors.grey.shade200,
        child: Icon(
          Icons.person,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(name),
      subtitle: Text(email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEmployeeDialog(
                context, provider, {'id': uid, 'name': name, 'email': email}),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () =>
                _showDeleteConfirmDialog(context, provider, uid, name),
          ),
          Switch(
            value: isActive,
            onChanged: (val) {
              provider.toggleEmployeeStatus(uid, isActive);
            },
            activeColor: const Color(0xFF1A237E),
          ),
        ],
      ),
    );
  }

  // Dialog para Agregar / Editar Empleado
  void _showEmployeeDialog(BuildContext context, AdminProvider provider,
      Map<String, dynamic>? employee) {
    final bool isEdit = employee != null;
    final TextEditingController nameController =
        TextEditingController(text: isEdit ? employee['name'] : '');
    final TextEditingController emailController =
        TextEditingController(text: isEdit ? employee['email'] : '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? 'Editar Empleado' : 'Agregar Empleado',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Nombre', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Correo', border: OutlineInputBorder()),
              ),
              if (!isEdit)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Se creará un perfil base. El empleado podrá registrarse en la app vinculándose a este correo.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                if (name.isNotEmpty && email.isNotEmpty) {
                  if (isEdit) {
                    provider.updateEmployee((employee['id'] ?? '').toString(), name, email);
                  } else {
                    provider.addEmployee(name, email);
                  }
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white),
              child: Text(isEdit ? 'Guardar' : 'Agregar'),
            ),
          ],
        );
      },
    );
  }

  // Dialog para confirmar eliminación
  void _showDeleteConfirmDialog(
      BuildContext context, AdminProvider provider, String uid, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Empleado',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
              '¿Estás seguro de que deseas eliminar a $name? Esta acción no se puede deshacer y el empleado perderá el beneficio corporativo.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteEmployee(uid);
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
