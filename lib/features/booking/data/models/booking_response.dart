import 'package:json_annotation/json_annotation.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/trip/data/models/points.dart';

part 'booking_response.g.dart';

/// Response from GET /api/trips/upcoming/driver/{driverId}
/// Maps from Swagger: DriverTripResponse
@JsonSerializable()
class DriverTripResponse {
  @JsonKey(name: 'tripId')
  final String? tripId;
  
  @JsonKey(name: 'vehicleNumber')
  final String vehicleNumber;
  
  @JsonKey(name: 'sourceAddress')
  final Points sourceAddress;
  
  @JsonKey(name: 'destinationAddress')
  final Points destinationAddress;
  
  @JsonKey(name: 'tripStartDateTime')
  final String tripStartDateTime;
  
  @JsonKey(name: 'offeredSeat')
  final int offeredSeat;
  
  /// Current number of passengers who joined
  @JsonKey(name: 'currSeats', defaultValue: 0)
  final int currSeats;
  
  /// List of passenger IDs who have joined
  @JsonKey(name: 'joinedRidersId')
  final List<String>? joinedRidersId;
  
  /// Trip status enum: pending/active/completed/cancelled
  @JsonKey(name: 'tripStatus')
  final String tripStatus;
  
  /// Route distance in kilometers
  @JsonKey(name: 'routeDistance')
  final double? routeDistance;
  
  /// Price per kilometer for this trip
  @JsonKey(name: 'pricePerKm')
  final double? pricePerKm;

  DriverTripResponse({
    this.tripId,
    required this.vehicleNumber,
    required this.sourceAddress,
    required this.destinationAddress,
    required this.tripStartDateTime,
    required this.offeredSeat,
    required this.currSeats,
    this.joinedRidersId,
    required this.tripStatus,
    this.routeDistance,
    this.pricePerKm,
  });

  factory DriverTripResponse.fromJson(Map<String, dynamic> json) => 
      _$DriverTripResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$DriverTripResponseToJson(this);

  /// Number of available seats remaining
  int get availableSeats => offeredSeat - currSeats;

  /// Estimated total earnings if all seats filled
  double get estimatedEarnings {
    if (routeDistance == null || pricePerKm == null) return 0.0;
    return routeDistance! * pricePerKm! * offeredSeat;
  }

  /// Estimated earnings from currently booked seats
  double get currentEarnings {
    if (routeDistance == null || pricePerKm == null) return 0.0;
    return routeDistance! * pricePerKm! * currSeats;
  }
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
  final String vehicleNumber;
  
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
  final double estimatedFare;
  
  @JsonKey(name: 'tripStartDateTime')
  final String tripStartDateTime;

  PassengerRideResponse({
    this.rideId,
    required this.tripId,
    required this.driverId,
    required this.vehicleNumber,
    required this.rideStatus,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.bookedSeats,
    required this.estimatedFare,
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
