import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../presentation/widgets/dual_context_toggle.dart';

class PassengerTripProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TripMode _currentMode = TripMode.personal;
  TripMode get currentMode => _currentMode;

  double _corporateLimit = 0.0;
  double get corporateLimit => _corporateLimit;

  double _proposedFare = 0.0;
  double get proposedFare => _proposedFare;

  bool _isLoadingLimit = false;
  bool get isLoadingLimit => _isLoadingLimit;

  PassengerTripProvider() {
    // Intentar cargar el límite si hay un usuario autenticado al iniciar
    if (_auth.currentUser != null) {
      fetchCorporateLimit();
    }
  }

  void setMode(TripMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;

      // Si cambia a corporativo y no hemos cargado el límite, lo cargamos
      if (mode == TripMode.corporate && _corporateLimit == 0.0) {
        fetchCorporateLimit();
      }
      notifyListeners();
    }
  }

  void setProposedFare(double fare) {
    _proposedFare = fare;
    notifyListeners();
  }

  // Lógica dinámica de excedente
  double get surplusAmount {
    if (_currentMode == TripMode.personal) return 0.0;

    final diff = _proposedFare - _corporateLimit;
    return diff > 0 ? diff : 0.0;
  }

  // Obtiene el límite del SaaS Empresarial guardado en Firestore
  Future<void> fetchCorporateLimit() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoadingLimit = true;
    notifyListeners();

    try {
      // Suponiendo que el usuario tiene un documento en 'users'
      // con un campo 'corporate_limit' o un ref a 'company'
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data()!.containsKey('corporate_limit')) {
        _corporateLimit =
            (userDoc.data()!['corporate_limit'] as num).toDouble();
      } else {
        _corporateLimit =
            0.0; // Valor por defecto si no se ha cargado/configurado
      }
    } catch (e) {
      debugPrint("Error obteniendo corporate limit: $e");
      _corporateLimit = 0.0;
    } finally {
      _isLoadingLimit = false;
      notifyListeners();
    }
  }
}
