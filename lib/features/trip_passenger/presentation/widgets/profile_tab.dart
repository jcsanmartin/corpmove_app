import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:corpmove_app/core/services/auth_service.dart';
import 'package:corpmove_app/core/utils/user_role.dart';
import 'package:corpmove_app/features/admin/data/admin_repository.dart';
import 'package:corpmove_app/features/trip_passenger/presentation/widgets/corporate_request_dialog.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _solicitarConductor() async {
    setState(() => _isLoading = true);
    try {
      await _authService.solicitarCambioRol(
        rolSolicitado: UserRole.driver,
        datosAdicionales: {
          'documentos': [],
          'notas': 'Solicitud de conductor',
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Solicitud enviada. Un administrador la revisará.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _solicitarCorporativo() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CorporateRequestDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Solicitud corporativa enviada.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _cancelarSolicitud() async {
    setState(() => _isLoading = true);
    try {
      await _authService.cancelarSolicitud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud cancelada.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('No hay usuario autenticado'));
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: AdminRepository().streamUserProfile(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Valores por defecto
        String role = 'normal';
        String? estadoSolicitud;
        Map<String, dynamic> extraData = {};

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          role = data['role'] as String? ?? 'normal';
          estadoSolicitud = data['estado_solicitud'] as String?;
          extraData = data;
        }

        // ⚠️ Condición exacta para mostrar opciones de upgrade
        final mostrarUpgrade = (role == 'normal') &&
            (estadoSolicitud == null || estadoSolicitud == 'ninguno');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      user!.photoURL != null && user!.photoURL!.isNotEmpty
                          ? NetworkImage(user!.photoURL!)
                          : null,
                  child: user!.photoURL == null || user!.photoURL!.isEmpty
                      ? Text(
                          user!.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : user!.email![0].toUpperCase(),
                          style:
                              const TextStyle(fontSize: 40, color: Colors.grey),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              // Nombre
              Center(
                child: Text(
                  user!.displayName?.isNotEmpty == true
                      ? user!.displayName!
                      : user!.email!.split('@').first,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              // Correo
              Center(
                child: Text(
                  user!.email!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),

              // Tarjeta de Rol Actual
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getRoleColor(role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getRoleIcon(role),
                            color: _getRoleColor(role), size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rol actual',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _roleToDisplayString(role),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(role.toUpperCase()),
                        backgroundColor: _getRoleColor(role).withOpacity(0.15),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Estado de solicitud (si existe)
              if (estadoSolicitud == 'pendiente') ...[
                _buildStatusCard(
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                  title: 'Solicitud en revisión',
                  subtitle:
                      'Tu solicitud está siendo evaluada por el equipo de CorpMove.',
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _cancelarSolicitud,
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Cancelar solicitud',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (estadoSolicitud == 'rechazado') ...[
                _buildStatusCard(
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  title: 'Solicitud rechazada',
                  subtitle:
                      extraData['motivo_rechazo'] ?? 'No se especificó motivo.',
                ),
                const SizedBox(height: 20),
              ],

              // ✅ OPCIONES DE UPGRADE (SOLO SI CORRESPONDE)
              if (mostrarUpgrade) ...[
                const Text(
                  'Mejora tu experiencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildUpgradeCard(
                  title: 'Conviértete en Conductor',
                  subtitle: 'Gana dinero llevando pasajeros con CorpMove',
                  icon: Icons.drive_eta,
                  color: const Color(0xFFFF6D00),
                  onTap: _isLoading ? null : _solicitarConductor,
                ),
                const SizedBox(height: 12),
                _buildUpgradeCard(
                  title: 'Afíliate como Empresa',
                  subtitle:
                      'Obtén beneficios corporativos y administra empleados',
                  icon: Icons.business,
                  color: const Color(0xFF1A237E),
                  onTap: _isLoading ? null : _solicitarCorporativo,
                ),
                const SizedBox(height: 24),
              ],

              // Mensaje si ya tiene un rol especial
              if (role != 'normal' &&
                  estadoSolicitud != 'pendiente' &&
                  estadoSolicitud != 'rechazado') ...[
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green.shade700),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            '¡Tu cuenta está verificada! Disfrutas de todos los beneficios de CorpMove.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Botón de cerrar sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Card(
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.black87;
      case 'admin':
        return Colors.purple;
      case 'driver':
        return Colors.orange;
      case 'employee':
        return const Color(0xFF1A237E);
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'owner':
        return Icons.admin_panel_settings;
      case 'admin':
        return Icons.business_center;
      case 'driver':
        return Icons.drive_eta;
      case 'employee':
        return Icons.badge;
      default:
        return Icons.person;
    }
  }

  String _roleToDisplayString(String role) {
    switch (role) {
      case 'normal':
        return 'Usuario Normal';
      case 'employee':
        return 'Empleado Corporativo';
      case 'driver':
        return 'Conductor';
      case 'admin':
        return 'Administrador';
      case 'owner':
        return 'Dueño';
      default:
        return role;
    }
  }
}
