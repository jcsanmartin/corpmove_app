import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/admin_provider.dart';

class CompanyConfigScreen extends StatefulWidget {
  const CompanyConfigScreen({super.key});

  @override
  State<CompanyConfigScreen> createState() => _CompanyConfigScreenState();
}

class _CompanyConfigScreenState extends State<CompanyConfigScreen> {
  // Color corporativo solicitado
  final Color primaryGreen = const Color(0xFF00C853);
  final Color darkBg = const Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F7), // Fondo claro como el mockup
        appBar: AppBar(
          backgroundColor: darkBg, // AppBar negro
          title: Text(
            'Admin Empresa',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000), // Responsive web
            child: Consumer<AdminProvider>(
              builder: (context, provider, child) {
                // Notificaciones de éxito o error
                _handleSnackBars(context, provider);

                if (provider.state == AdminState.loading &&
                    provider.companyData == null) {
                  return Center(
                      child: CircularProgressIndicator(color: primaryGreen));
                }

                if (provider.state == AdminState.error &&
                    provider.companyData == null) {
                  return Center(child: Text('Error: ${provider.errorMessage}'));
                }

                if (provider.companyData == null) {
                  return const Center(child: Text('Cargando datos...'));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Tarjeta de Estadísticas de Empleados
                      _buildStatsCard(provider),
                      const SizedBox(height: 24),

                      // 2. Tarjeta de Configuración de Convenio
                      _buildConfigCard(context, provider),
                      const SizedBox(height: 24),

                      // 3. Tarjeta de Lista de Empleados
                      _buildEmployeesListCard(provider),
                    ],
                  ),
                );
              },
            ),
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
            SnackBar(
              content: const Text('Cambio guardado en Firebase exitosamente.'),
              backgroundColor: primaryGreen,
              duration: const Duration(seconds: 2),
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
      });
    }
  }

  Widget _buildStatsCard(AdminProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Empleados afiliados',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(provider.activeEmployeesCount.toString(),
                    'Activos', primaryGreen),
                _buildStatItem(provider.pendingEmployeesCount.toString(),
                    'Pendientes', Colors.orange),
                _buildStatItem(provider.inactiveEmployeesCount.toString(),
                    'Inactivos', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
              fontSize: 32, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildConfigCard(BuildContext context, AdminProvider provider) {
    final company = provider.companyData!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuración de Convenio',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            _buildConfigRow(
              context,
              provider,
              title: 'Techo por viaje',
              value: '\$${company['corporate_limit'] ?? 0}',
              fieldKey: 'corporate_limit',
              isNumber: true,
            ),
            const Divider(height: 32),
            _buildConfigRow(
              context,
              provider,
              title: 'Viajes diarios máximos',
              value: '${company['daily_trips_limit'] ?? 0}',
              fieldKey: 'daily_trips_limit',
              isNumber: true,
            ),
            const Divider(height: 32),
            _buildConfigRow(
              context,
              provider,
              title: 'Horario permitido',
              value: company['allowed_schedules'] is List
                  ? company['allowed_schedules'].join(', ')
                  : (company['allowed_schedules'] ?? 'Sin definir').toString(),
              fieldKey: 'allowed_schedules',
              isNumber: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(BuildContext context, AdminProvider provider,
      {required String title,
      required String value,
      required String fieldKey,
      required bool isNumber}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            flex: 2,
            child: Text(title,
                style: GoogleFonts.inter(fontSize: 15, color: Colors.black87))),
        Expanded(
            flex: 2,
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)),
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showEditDialog(
                  context, provider, title, value, fieldKey, isNumber),
              child: Text('Editar',
                  style: GoogleFonts.inter(color: Colors.indigo)),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, AdminProvider provider,
      String title, String currentValue, String fieldKey, bool isNumber) {
    final TextEditingController editController = TextEditingController(
        text: currentValue.replaceAll('\$', '').replaceAll(',', ''));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Editar $title',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: editController,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryGreen)),
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
                Navigator.pop(dialogContext); // Cerrar diálogo

                dynamic newValue;
                if (isNumber) {
                  newValue = double.tryParse(editController.text) ?? 0.0;
                } else {
                  // Si es array (horarios), lo pasamos a lista simple por ahora
                  if (fieldKey == 'allowed_schedules') {
                    newValue = [editController.text];
                  } else {
                    newValue = editController.text;
                  }
                }

                // Ejecutar update
                await provider.updateConfigField(fieldKey, newValue);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              child: const Text('Guardar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmployeesListCard(AdminProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Empleados recientes',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (provider.employees.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No hay empleados registrados en esta empresa.'),
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

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: primaryGreen.withOpacity(0.2),
                      child: Icon(Icons.person, color: primaryGreen),
                    ),
                    title: Text(emp['name'] ?? 'Usuario sin nombre',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: Text(emp['email'] ?? 'Sin correo',
                        style: GoogleFonts.inter(color: Colors.grey.shade600)),
                    trailing: Switch(
                      value: isActive,
                      activeColor: Colors.indigo,
                      onChanged: (val) {
                        provider.toggleEmployeeStatus(
                            emp['uid'], emp['is_active'] ?? false);
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
