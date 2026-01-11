import 'package:json_annotation/json_annotation.dart';
import 'points.dart';

part 'offer_ride_request.g.dart';

/// Converter for Points serialization
class PointsConverter implements JsonConverter<Points, Map<String, dynamic>> {
  const PointsConverter();

  @override
  Points fromJson(Map<String, dynamic> json) => Points.fromJson(json);

  @override
  Map<String, dynamic> toJson(Points object) => object.toJson();
}

/// Converter for DateTime to ISO 8601 without milliseconds
/// Backend rejects dates with milliseconds (.000Z)
class DateTimeConverter implements JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) {
    // Format: 2026-01-25T17:00:00Z (no milliseconds)
    final utc = object.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}Z';
  }
}

/// Request body for POST /api/trips/offer
/// Maps from Swagger: OfferRideRequest
@JsonSerializable(includeIfNull: false)
class OfferRideRequest {
  final String driverId;
  final String vehicleNumber;
  
  @PointsConverter()
  final Points sourceAddress;
  
  @PointsConverter()
  final Points destinationAddress;
  
  @DateTimeConverter()
  @JsonKey(name: 'tripStartDateTime')
  final DateTime tripStartDateTime;
  
  @JsonKey(name: 'offeredSeat')
  final int offeredSeat;

  OfferRideRequest({
    required this.driverId,
    required this.vehicleNumber,
    required this.sourceAddress,
    required this.destinationAddress,
    required this.tripStartDateTime,
    required this.offeredSeat,
  });

  factory OfferRideRequest.fromJson(Map<String, dynamic> json) => 
      _$OfferRideRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$OfferRideRequestToJson(this);
}
