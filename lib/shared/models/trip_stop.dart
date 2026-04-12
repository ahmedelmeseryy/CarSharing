class TripStop {
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime? estimatedArrivalTime;
  final int order; // Order in the route (0 = first stop after origin)

  TripStop({
    required this.address,
    this.latitude,
    this.longitude,
    this.estimatedArrivalTime,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'estimatedArrivalTime': estimatedArrivalTime?.toIso8601String(),
      'order': order,
    };
  }

  factory TripStop.fromMap(Map<String, dynamic> map) {
    return TripStop(
      address: map['address'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      estimatedArrivalTime: map['estimatedArrivalTime'] != null
          ? DateTime.parse(map['estimatedArrivalTime'])
          : null,
      order: map['order'] ?? 0,
    );
  }
}
