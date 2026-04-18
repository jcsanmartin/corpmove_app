abstract class TripCreationEvent {}

class CreateTripStarted extends TripCreationEvent {
  final String type;
  final Map<String, dynamic> convenio;

  CreateTripStarted({required this.type, required this.convenio});
}