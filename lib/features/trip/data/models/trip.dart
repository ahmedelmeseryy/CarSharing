import 'package:json_annotation/json_annotation.dart';
import 'points.dart';

part 'trip.g.dart';

/// Represents a Trip when searching for available trips
/// Maps from Swagger: Trip (returned by search endpoints)
@JsonSerializable()
class Trip {
  final String? tripId;
  final String tripStatus;
  final String vehicleNumber;
  final String driverId;
  final Points sourceAddress;
  final Points destinationAddress;
  final Map<String, dynamic>? sourceLocation;
  final Map<String, dynamic>? destinationLocation;
  
  @JsonKey(name: 'offeredSeat')
  final int offeredSeat;
  
  @JsonKey(name: 'currSeats', defaultValue: 0)
  final int currSeats;
  
  @JsonKey(name: 'tripStartDateTimeUTC')
  final DateTime tripStartDateTime;
  
  @JsonKey(name: 'tripTimezone')
  final String? tripTimezone;
  
  @JsonKey(name: 'routeGeometry')
  final Map<String, dynamic>? routeGeometry;
  
  @JsonKey(name: 'routeDistance')
  final double? routeDistance;
  
  @JsonKey(name: 'routeDuration')
  final double? routeDuration;
  
  @JsonKey(name: 'pricePerKm')
  final double? pricePerKm;
  
  @JsonKey(name: 'joinedRidersId')
  final List<dynamic>? joinedRidersId;
  
  @JsonKey(name: 'createdDate')
  final DateTime? createdDate;

  Trip({
    this.tripId,
    required this.tripStatus,
    required this.vehicleNumber,
    required this.driverId,
    required this.sourceAddress,
    required this.destinationAddress,
    this.sourceLocation,
    this.destinationLocation,
    required this.offeredSeat,
    required this.currSeats,
    required this.tripStartDateTime,
    this.tripTimezone,
    this.routeGeometry,
    this.routeDistance,
    this.routeDuration,
    this.pricePerKm,
    this.joinedRidersId,
    this.createdDate,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
  Map<String, dynamic> toJson() => _$TripToJson(this);

  /// Helper: available seats = offered - current
  int get availableSeats => offeredSeat - currSeats;

  /// Helper: estimated fare
  double get estimatedFare {
    if (pricePerKm == null || routeDistance == null) return 0;
    return pricePerKm! * (routeDistance! / 1000);
  }

  @override
  String toString() => 'Trip($tripId: ${sourceAddress.placeAddress} → ${destinationAddress.placeAddress})';
}
