class TripOffer {
  final String id;
  final String tripId;
  final String driverId;
  final String driverName;
  final double offeredFare;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  TripOffer({
    required this.id,
    required this.tripId,
    required this.driverId,
    required this.driverName,
    required this.offeredFare,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'driver_id': driverId,
      'driver_name': driverName,
      'offered_fare': offeredFare,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TripOffer.fromMap(Map<String, dynamic> map, String docId) {
    return TripOffer(
      id: docId,
      tripId: map['trip_id'] ?? '',
      driverId: map['driver_id'] ?? '',
      driverName: map['driver_name'] ?? '',
      offeredFare: (map['offered_fare'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
