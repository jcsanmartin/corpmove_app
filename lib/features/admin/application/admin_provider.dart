import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/admin_repository.dart';

enum AdminState { initial, loading, success, error, noCompany }

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository = AdminRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AdminState _state = AdminState.initial;
  AdminState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String? _currentCompanyId;
  Map<String, dynamic>? _companyData;
  Map<String, dynamic>? get companyData => _companyData;

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> get employees => _employees;

  StreamSubscription<Map<String, dynamic>?>? _companySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _employeesSubscription;

  AdminProvider() {
    _initialize();
  }

  bool get isLoading => _state == AdminState.loading;

  Future<void> _initialize() async {
    _setLoading();
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener el company_id del usuario desde Supabase
      _currentCompanyId = await _repository.getUserCompanyId(user.uid);

      if (_currentCompanyId == null) {
        _state = AdminState.noCompany;
        notifyListeners();
        return;
      }

      // 1. Escuchar la configuración de la empresa en tiempo real
      _companySubscription = _repository
          .streamCompanyConfig(_currentCompanyId!)
          .listen((data) {
        if (data == null) {
          _setError('La empresa asignada no existe en la base de datos.');
        } else {
          _companyData = data;
          notifyListeners();
        }
      }, onError: (e) {
        _setError('Error al escuchar la empresa: $e');
      });

      // 2. Escuchar la lista de empleados en tiempo real
      _employeesSubscription = _repository
          .streamCompanyEmployees(_currentCompanyId!)
          .listen((rows) {
        _employees = rows;
        notifyListeners();
      }, onError: (e) {
        debugPrint('[AdminProvider] Error empleados: $e');
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // CONFIGURACIÓN
  // ─────────────────────────────────────────────

  Future<void> updateConfigField(String field, dynamic value) async {
    if (_currentCompanyId == null) return;
    _setLoading();
    try {
      await _repository.updateConfig(_currentCompanyId!, field, value);
      _setSuccess();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // EMPLEADOS
  // ─────────────────────────────────────────────

  Future<void> toggleEmployeeStatus(String userId, bool currentStatus) async {
    try {
      // El stream de Supabase actualiza la lista automáticamente.
      await _repository.updateEmployeeStatus(userId, !currentStatus);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> addEmployee(String name, String email) async {
    if (_currentCompanyId == null) return;
    _setLoading();
    try {
      await _repository.addEmployee(_currentCompanyId!, name, email);
      _setSuccess();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> updateEmployee(String uid, String name, String email) async {
    _setLoading();
    try {
      await _repository.updateEmployeeInfo(uid, name, email);
      _setSuccess();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> deleteEmployee(String uid) async {
    _setLoading();
    try {
      await _repository.deleteEmployee(uid);
      _setSuccess();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // SOLICITUDES
  // ─────────────────────────────────────────────

  Future<void> approveRequest(String uid) async {
    try {
      // El stream de Supabase refleja el cambio en tiempo real.
      await _repository.approveRequest(uid);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> rejectRequest(String uid) async {
    try {
      // El stream de Supabase refleja el cambio en tiempo real.
      await _repository.rejectRequest(uid);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // EMPRESA
  // ─────────────────────────────────────────────

  Future<void> createCompany(String companyName) async {
    _setLoading();
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');
      _currentCompanyId = await _repository.createCompany(companyName, user.uid);
      await _initialize();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // CONTADORES DASHBOARD
  // ─────────────────────────────────────────────

  int get activeEmployeesCount => _employees
      .where((e) => e['estado_solicitud'] == 'aprobado' || e['is_active'] == true)
      .length;
  int get pendingEmployeesCount =>
      _employees.where((e) => e['estado_solicitud'] == 'pendiente').length;
  int get inactiveEmployeesCount => _employees
      .where((e) => e['estado_solicitud'] == 'rechazado' || e['is_active'] == false)
      .length;

  // ─────────────────────────────────────────────
  // VIAJES CORPORATIVOS (Reportes)
  // ─────────────────────────────────────────────

  List<Map<String, dynamic>> _companyTrips = [];
  List<Map<String, dynamic>> get companyTrips => _companyTrips;

  List<Map<String, dynamic>> _weeklyTrips = [];
  List<Map<String, dynamic>> get weeklyTrips => _weeklyTrips;

  bool _tripsLoaded = false;
  bool get tripsLoaded => _tripsLoaded;

  String? get currentCompanyId => _currentCompanyId;

  Future<void> loadCompanyTrips() async {
    if (_currentCompanyId == null) return;
    try {
      _companyTrips = await _repository.fetchCompanyTrips(_currentCompanyId!);
      _weeklyTrips = await _repository.fetchWeeklyTrips(_currentCompanyId!);
      _tripsLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[AdminProvider] Error cargando viajes: $e');
    }
  }

  double get totalSpent {
    double total = 0;
    for (final t in _companyTrips) {
      total += (t['cost'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  int get completedTripsCount => _companyTrips
      .where((t) => t['status'] == 'completado' || t['status'] == 'finalizado')
      .length;

  Map<String, int> get tripsPerDay {
    final Map<String, int> result = {};
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    for (final t in _weeklyTrips) {
      final created = t['created_at'] as String?;
      if (created != null) {
        try {
          final dt = DateTime.parse(created).toLocal();
          final dayName = days[dt.weekday - 1];
          result[dayName] = (result[dayName] ?? 0) + 1;
        } catch (_) {}
      }
    }
    return result;
  }

  Map<String, double> get spendPerEmployee {
    final Map<String, double> result = {};
    for (final t in _companyTrips) {
      final userId = t['user_id'] as String? ?? 'desconocido';
      final cost = (t['cost'] as num?)?.toDouble() ?? 0;
      result[userId] = (result[userId] ?? 0) + cost;
    }
    return result;
  }

  String getEmployeeName(String userId) {
    final emp = _employees.where((e) => e['id'] == userId).toList();
    if (emp.isNotEmpty) {
      return emp.first['display_name'] ?? emp.first['name'] ?? emp.first['email'] ?? 'Empleado';
    }
    return 'Empleado';
  }

  // ─────────────────────────────────────────────
  // ESTADO
  // ─────────────────────────────────────────────

  void _setLoading() {
    _state = AdminState.loading;
    notifyListeners();
  }

  void _setSuccess() {
    _state = AdminState.success;
    notifyListeners();
  }

  void _setError(String message) {
    _state = AdminState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearState() {
    if (_state == AdminState.success || _state == AdminState.error) {
      _state = AdminState.initial;
      _errorMessage = '';
    }
  }

  @override
  void dispose() {
    _companySubscription?.cancel();
    _employeesSubscription?.cancel();
    super.dispose();
  }
}
