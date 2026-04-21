import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyConfigProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Map<String, dynamic>? _companyData;
  Map<String, dynamic>? get companyData => _companyData;

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> get employees => _employees;

  String? _currentCompanyId;

  // Carga inicial de datos
  Future<void> loadCompanyData(String companyId) async {
    _isLoading = true;
    _currentCompanyId = companyId;
    notifyListeners();

    try {
      // 1. Cargar datos de la empresa
      final companyDoc =
          await _firestore.collection('companies').doc(companyId).get();
      if (companyDoc.exists) {
        _companyData = companyDoc.data();
      } else {
        // Para pruebas, si no existe, lo creamos con valores por defecto
        _companyData = {
          'company_name': 'Mi Empresa Demo',
          'corporate_limit': 15000,
          'daily_trips_limit': 2,
          'allowed_schedules': ['08:00-18:00'],
        };
        await _firestore
            .collection('companies')
            .doc(companyId)
            .set(_companyData!);
      }

      // 2. Cargar empleados asociados a esta empresa
      final usersSnapshot = await _firestore
          .collection('users')
          .where('company_id', isEqualTo: companyId)
          .get();

      _employees = usersSnapshot.docs.map((doc) {
        var data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint("Error loading company data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar el límite corporativo
  Future<void> updateCorporateLimit(double newLimit) async {
    if (_currentCompanyId == null) return;

    _isSaving = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      // 1. Actualizar el documento de la empresa
      final companyRef =
          _firestore.collection('companies').doc(_currentCompanyId);
      batch.update(companyRef, {'corporate_limit': newLimit});

      // 2. Opcional: Actualizar el campo 'corporate_limit' en cada usuario asociado
      // para que la app de pasajero lo lea directamente si está configurada así.
      final usersSnapshot = await _firestore
          .collection('users')
          .where('company_id', isEqualTo: _currentCompanyId)
          .get();

      for (var doc in usersSnapshot.docs) {
        batch.update(doc.reference, {'corporate_limit': newLimit});
      }

      // Ejecutar la escritura atómica
      await batch.commit();

      // Actualizar estado local
      if (_companyData != null) {
        _companyData!['corporate_limit'] = newLimit;
      }
    } catch (e) {
      debugPrint("Error updating corporate limit: $e");
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
