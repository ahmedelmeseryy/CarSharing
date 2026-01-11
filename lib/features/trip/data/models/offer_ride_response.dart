import 'package:json_annotation/json_annotation.dart';
import 'points.dart';

part 'offer_ride_response.g.dart';

/// Response from POST /api/trips/offer
/// Maps from Swagger: OfferRideResponse (wrapped in ApiResponseOfferRideResponse)
@JsonSerializable()
class OfferRideResponse {
  final String? tripId;
  final String vehicleNumber;
  final Points sourceAddress;
  final Points destinationAddress;
  
  @JsonKey(name: 'tripStartDateTime')
  final DateTime tripStartDateTime;
  
  @JsonKey(name: 'tripTimezone')
  final String? tripTimezone;
  
  @JsonKey(name: 'offeredSeat', defaultValue: 0)
  final int offeredSeat;
  
  @JsonKey(name: 'availableSeats', defaultValue: 0)
  final int availableSeats;
  
  @JsonKey(name: 'routeGeometry')
  final Map<String, dynamic>? routeGeometry;
  
  @JsonKey(name: 'routeDistanceInMeters')
  final double? routeDistanceInMeters;
  
  @JsonKey(name: 'routeDistanceInKm')
  final double? routeDistanceInKm;
  
  @JsonKey(name: 'routeDurationInSeconds')
  final double? routeDurationInSeconds;
  
  @JsonKey(name: 'routeDurationInMinutes')
  final double? routeDurationInMinutes;
  
  @JsonKey(name: 'tripCreated')
  final bool tripCreated;
  
  @JsonKey(name: 'errorMessage')
  final String? errorMessage;

  OfferRideResponse({
    this.tripId,
    required this.vehicleNumber,
    required this.sourceAddress,
    required this.destinationAddress,
    required this.tripStartDateTime,
    this.tripTimezone,
    required this.offeredSeat,
    required this.availableSeats,
    this.routeGeometry,
    this.routeDistanceInMeters,
    this.routeDistanceInKm,
    this.routeDurationInSeconds,
    this.routeDurationInMinutes,
    required this.tripCreated,
    this.errorMessage,
  });

  factory OfferRideResponse.fromJson(Map<String, dynamic> json) => 
      _$OfferRideResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$OfferRideResponseToJson(this);
}
