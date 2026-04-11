// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_ride_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfferRideResponse _$OfferRideResponseFromJson(
  Map<String, dynamic> json,
) => OfferRideResponse(
  tripId: json['tripId'] as String?,
  vehicleNumber: json['vehicleNumber'] as String?,
  sourceAddress: json['sourceAddress'] == null
      ? null
      : Points.fromJson(json['sourceAddress'] as Map<String, dynamic>),
  destinationAddress: json['destinationAddress'] == null
      ? null
      : Points.fromJson(json['destinationAddress'] as Map<String, dynamic>),
  tripStartDateTime: json['tripStartDateTime'] == null
      ? null
      : DateTime.parse(json['tripStartDateTime'] as String),
  tripTimezone: json['tripTimezone'] as String?,
  offeredSeat: (json['offeredSeat'] as num?)?.toInt() ?? 0,
  availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 0,
  routeGeometry: json['routeGeometry'] as Map<String, dynamic>?,
  routeDistanceInMeters: (json['routeDistanceInMeters'] as num?)?.toDouble(),
  routeDistanceInKm: (json['routeDistanceInKm'] as num?)?.toDouble(),
  routeDurationInSeconds: (json['routeDurationInSeconds'] as num?)?.toDouble(),
  routeDurationInMinutes: (json['routeDurationInMinutes'] as num?)?.toDouble(),
  tripCreated: json['tripCreated'] as bool? ?? false,
  errorMessage: json['errorMessage'] as String?,
);

Map<String, dynamic> _$OfferRideResponseToJson(OfferRideResponse instance) =>
    <String, dynamic>{
      'tripId': instance.tripId,
      'vehicleNumber': instance.vehicleNumber,
      'sourceAddress': instance.sourceAddress,
      'destinationAddress': instance.destinationAddress,
      'tripStartDateTime': instance.tripStartDateTime?.toIso8601String(),
      'tripTimezone': instance.tripTimezone,
      'offeredSeat': instance.offeredSeat,
      'availableSeats': instance.availableSeats,
      'routeGeometry': instance.routeGeometry,
      'routeDistanceInMeters': instance.routeDistanceInMeters,
      'routeDistanceInKm': instance.routeDistanceInKm,
      'routeDurationInSeconds': instance.routeDurationInSeconds,
      'routeDurationInMinutes': instance.routeDurationInMinutes,
      'tripCreated': instance.tripCreated,
      'errorMessage': instance.errorMessage,
    };
