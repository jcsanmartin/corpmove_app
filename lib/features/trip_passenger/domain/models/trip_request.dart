class TripRequest {
  final String id;
  final String passengerId;
  final String passengerName;
  final String tripType; // 'personal' o 'corporate'
  final String companyId; // Para viajes corporativos
  final double proposedFare;
  final String status; // 'searching', 'negotiating', 'accepted', 'completed'
  final DateTime createdAt;

  TripRequest({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    required this.tripType,
    this.companyId = '',
    required this.proposedFare,
    this.status = 'searching',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'passenger_id': passengerId,
      'passenger_name': passengerName,
      'trip_type': tripType,
      'company_id': companyId,
      'proposed_fare': proposedFare,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TripRequest.fromMap(Map<String, dynamic> map) {
    return TripRequest(
      id: map['id'] ?? '',
      passengerId: map['passenger_id'] ?? '',
      passengerName: map['passenger_name'] ?? '',
      tripType: map['trip_type'] ?? 'personal',
      companyId: map['company_id'] ?? '',
      proposedFare: (map['proposed_fare'] ?? 0).toDouble(),
      status: map['status'] ?? 'searching',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
