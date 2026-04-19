import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:corpmove_app/core/services/auth_service.dart';
import 'package:corpmove_app/core/utils/user_role.dart';

class SolicitudesPendientes extends StatefulWidget {
  const SolicitudesPendientes({super.key});

  @override
  State<SolicitudesPendientes> createState() => _SolicitudesPendientesState();
}

class _SolicitudesPendientesState extends State<SolicitudesPendientes> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes Pendientes'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _authService.getSolicitudesPendientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay solicitudes pendientes', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final nombre = data['displayName'] ?? 'Sin nombre';
              final email = data['email'] ?? '';
              final rolSolicitado = data['rol_solicitado'] as String? ?? 'driver';
              final notas = data['notas'] ?? '';
              final fecha = (data['fecha_solicitud'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(email, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(rolSolicitado.toUpperCase()),
                            backgroundColor: _getRoleColor(rolSolicitado).withOpacity(0.15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (notas.isNotEmpty) Text('Notas: $notas'),
                      if (fecha != null) Text('Solicitado: ${_formatDate(fecha)}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _rechazar(context, docId),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Rechazar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _aprobar(context, docId, rolSolicitado),
                            icon: const Icon(Icons.check),
                            label: const Text('Aprobar'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _aprobar(BuildContext context, String docId, String rolSolicitado) async {
    // Obtener el UID del documento
    final doc = await FirebaseFirestore.instance.collection('users').doc(docId).get();
    final uid = doc.data()?['uid'] as String? ?? docId;

    UserRole nuevoRol;
    switch (rolSolicitado) {
      case 'driver': nuevoRol = UserRole.driver; break;
      case 'employee': nuevoRol = UserRole.employee; break;
      case 'admin': nuevoRol = UserRole.admin; break;
      default: nuevoRol = UserRole.normal;
    }

    try {
      await _authService.aprobarSolicitud(uid, nuevoRol);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Solicitud aprobada'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rechazar(BuildContext context, String docId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(docId).get();
    final uid = doc.data()?['uid'] as String? ?? docId;

    try {
      await _authService.rechazarSolicitud(uid, motivo: 'No cumple requisitos');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Solicitud rechazada'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'driver': return Colors.orange;
      case 'employee': return const Color(0xFF1A237E);
      case 'admin': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}