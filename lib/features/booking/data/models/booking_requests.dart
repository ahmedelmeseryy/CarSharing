import 'package:json_annotation/json_annotation.dart';
import 'package:carsharing/features/trip/data/models/points.dart';

part 'booking_requests.g.dart';

/// Converter for Points serialization
class PointsConverter implements JsonConverter<Points, Map<String, dynamic>> {
  const PointsConverter();

  @override
  Points fromJson(Map<String, dynamic> json) => Points.fromJson(json);

  @override
  Map<String, dynamic> toJson(Points object) => object.toJson();
}

/// Request body for POST /api/bookings/join
/// Maps from Swagger: JoinTripRequest
@JsonSerializable()
class JoinTripRequest {
  final String tripId;
  final String passengerId;
  final String driverId;
  
  @PointsConverter()
  final Points pickupPoint;
  
  @PointsConverter()
  final Points destinationPoint;
  
  @JsonKey(name: 'rideStartTime')
  final String rideStartTime;
  
  @JsonKey(name: 'requestedSeats')
  final int requestedSeats;

  JoinTripRequest({
    required this.tripId,
    required this.passengerId,
    required this.driverId,
    required this.pickupPoint,
    required this.destinationPoint,
    required this.rideStartTime,
    required this.requestedSeats,
  });

  factory JoinTripRequest.fromJson(Map<String, dynamic> json) => 
      _$JoinTripRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$JoinTripRequestToJson(this);
}

/// Request body for POST /api/bookings/cancel or POST /api/trips/cancel
/// Maps from Swagger: CancelTripRequest
@JsonSerializable(includeIfNull: false)
class CancelTripRequest {
  final String userId;
  final String tripId;
  final String? rideId;
  final String? cancellationReason;

  CancelTripRequest({
    required this.userId,
    required this.tripId,
    this.rideId,
    this.cancellationReason,
  });

  factory CancelTripRequest.fromJson(Map<String, dynamic> json) => 
      _$CancelTripRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$CancelTripRequestToJson(this);
}
