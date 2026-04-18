abstract class TripCreationState {}

class TripInitial extends TripCreationState {}
class TripLoading extends TripCreationState {}
class TripSuccess extends TripCreationState {}
class TripError extends TripCreationState {
  final String message;
  TripError(this.message);
}