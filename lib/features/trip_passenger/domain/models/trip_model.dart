import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String? id;
  final String passengerId;
  final String type; // "CORPORATE" o "PERSONAL"
  final String status;
  final Map<String, dynamic> convenioData;
  final Map<String, dynamic>? pickup;
  final double excedenteCobrado;

  TripModel({
    this.id,
    required this.passengerId,
    required this.type,
    required this.status,
    required this.convenioData,
    this.pickup,
    this.excedenteCobrado = 0.0,
  });

  // --- EL TRADUCTOR: De Firebase a tu App ---
  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return TripModel(
      id: doc.id,
      passengerId: data['passengerId'] ?? '',
      type: data['type'] ?? 'PERSONAL',
      status: data['status'] ?? 'WAITING',
      convenioData: data['convenioData'] ?? {},
      pickup: data['pickup'],
      excedenteCobrado: (data['excedenteCobrado'] ?? 0).toDouble(),
    );
  }

  // --- EL ENVIADO: De tu App a Firebase ---
  Map<String, dynamic> toFirestore() {
    return {
      "passengerId": passengerId,
      "type": type,
      "status": status,
      "convenioData": convenioData,
      "pickup": pickup,
      "excedenteCobrado": excedenteCobrado,
    };
  }
}