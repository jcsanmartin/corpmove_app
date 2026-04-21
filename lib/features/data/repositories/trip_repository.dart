import 'package:cloud_firestore/cloud_firestore.dart';
import '../../trip_passenger/domain/models/trip_request.dart';
import '../../trip_passenger/domain/models/trip_offer.dart';

class TripRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Crear la solicitud de viaje (Propuesta inicial del pasajero)
  Future<String> createTripRequest(TripRequest request) async {
    try {
      final docRef = _firestore.collection('trips').doc();
      final requestWithId = TripRequest(
        id: docRef.id,
        passengerId: request.passengerId,
        passengerName: request.passengerName,
        tripType: request.tripType,
        companyId: request.companyId,
        proposedFare: request.proposedFare,
        status: request.status,
        createdAt: request.createdAt,
      );

      await docRef.set(requestWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception("Error al crear la solicitud de viaje: $e");
    }
  }

  // 2. Escuchar en tiempo real las ofertas de los conductores
  Stream<List<TripOffer>> listenToDriverOffers(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('offers')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TripOffer.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // 3. Aceptar una oferta específica de un conductor
  Future<void> acceptOffer(String tripId, String offerId) async {
    try {
      final batch = _firestore.batch();
      
      final tripRef = _firestore.collection('trips').doc(tripId);
      final offerRef = tripRef.collection('offers').doc(offerId);

      // Actualizar el estado del viaje
      batch.update(tripRef, {'status': 'accepted'});
      
      // Actualizar el estado de la oferta ganadora
      batch.update(offerRef, {'status': 'accepted'});

      await batch.commit();
    } catch (e) {
      throw Exception("Error al aceptar la oferta: $e");
    }
  }
}
