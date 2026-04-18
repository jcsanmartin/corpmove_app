import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Importamos el modelo usando la ruta completa para evitar errores
import 'package:corpmove_app/features/trip_passenger/domain/models/trip_model.dart';

import 'trip_creation_event.dart';
import 'trip_creation_state.dart';

class TripCreationBloc extends Bloc<TripCreationEvent, TripCreationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TripCreationBloc() : super(TripInitial()) {
    on<CreateTripStarted>((event, emit) async {
      emit(TripLoading());

      try {
        final nuevoViaje = TripModel(
          passengerId: "user_empleado_123", 
          type: event.type,
          status: "BIDDING",
          convenioData: event.convenio,
        );

        await _firestore.collection('trips').add(nuevoViaje.toFirestore());

        emit(TripSuccess());
      } catch (e) {
        emit(TripError("Error de Firebase: $e"));
      }
    });
  }
}