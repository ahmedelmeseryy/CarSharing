import 'package:json_annotation/json_annotation.dart';
import 'package:carsharing/features/trip/data/models/points.dart';

part 'booking_response.g.dart';

/// Response from GET /api/trips/upcoming/driver/{driverId}
/// Maps from Swagger: DriverTripResponse
@JsonSerializable()
class DriverTripResponse {
  @JsonKey(name: 'tripId')
  final String? tripId;
  
  @JsonKey(name: 'driverId')
  final String? driverId;
  
  @JsonKey(name: 'vehicleNumber')
  final String? vehicleNumber;

  final String? tripStatus;

  final Points? sourceAddress;

  final Points? destinationAddress;

  final String? tripStartDateTime;

  @JsonKey(name: 'tripTimezone')
  final String? tripTimezone;

  @JsonKey(name: 'totalSeats', defaultValue: 0)
  final int totalSeats;

  @JsonKey(name: 'availableSeats', defaultValue: 0)
  final int availableSeats;
  
  @JsonKey(name: 'bookedSeats', defaultValue: 0)
  final int bookedSeats;
  
  @JsonKey(name: 'passengers')
  final List<dynamic>? passengers;
  
  @JsonKey(name: 'routeDistanceInKm')
  final double? routeDistanceInKm;
  
  @JsonKey(name: 'routeDurationInMinutes')
  final double? routeDurationInMinutes;
  
  @JsonKey(name: 'pricePerSeat')
  final double? pricePerSeat;

  DriverTripResponse({
    this.tripId,
    this.driverId,
    this.vehicleNumber,
    this.tripStatus,
    this.sourceAddress,
    this.destinationAddress,
    this.tripStartDateTime,
    this.tripTimezone,
    required this.totalSeats,
    required this.availableSeats,
    required this.bookedSeats,
    this.passengers,
    this.routeDistanceInKm,
    this.routeDurationInMinutes,
    this.pricePerSeat,
  });

  factory DriverTripResponse.fromJson(Map<String, dynamic> json) =>
      _$DriverTripResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DriverTripResponseToJson(this);

  /// Estimated total earnings if all seats filled
  double get estimatedEarnings => (pricePerSeat ?? 0) * totalSeats;

  /// Estimated earnings from currently booked seats
  double get currentEarnings => (pricePerSeat ?? 0) * bookedSeats;
}

/// Response from GET /api/bookings/upcoming/passenger/{passengerId}
/// Maps from Swagger: PassengerRideResponse
@JsonSerializable()
class PassengerRideResponse {
  @JsonKey(name: 'rideId')
  final String? rideId;
  
  @JsonKey(name: 'tripId')
  final String tripId;
  
  @JsonKey(name: 'driverId')
  final String driverId;
  
  @JsonKey(name: 'vehicleNumber')
  final String? vehicleNumber;
  
  /// Status of the booking: pending/confirmed/completed/cancelled
  @JsonKey(name: 'rideStatus')
  final String rideStatus;
  
  @JsonKey(name: 'pickupLocation')
  final Points pickupLocation;
  
  @JsonKey(name: 'dropoffLocation')
  final Points dropoffLocation;
  
  /// Number of seats booked by this passenger
  @JsonKey(name: 'bookedSeats')
  final int bookedSeats;
  
  /// Estimated fare for this booking
  @JsonKey(name: 'estimatedFare')
  final double? estimatedFare;
  
  @JsonKey(name: 'tripStartDateTime')
  final String tripStartDateTime;

  PassengerRideResponse({
    this.rideId,
    required this.tripId,
    required this.driverId,
    this.vehicleNumber,
    required this.rideStatus,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.bookedSeats,
    this.estimatedFare,
    required this.tripStartDateTime,
  });

  factory PassengerRideResponse.fromJson(Map<String, dynamic> json) => 
      _$PassengerRideResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$PassengerRideResponseToJson(this);

  /// Friendly status label
  String get statusLabel {
    switch (rideStatus.toLowerCase()) {
      case 'pending':
        return 'Awaiting Confirmation';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return rideStatus;
    }
  }

  /// Check if ride is still active/upcoming
  bool get isActive {
    final status = rideStatus.toLowerCase();
    return status == 'pending' || status == 'confirmed';
  }
}
