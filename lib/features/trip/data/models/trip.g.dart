// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trip _$TripFromJson(Map<String, dynamic> json) => Trip(
  tripId: json['tripId'] as String?,
  tripStatus: json['tripStatus'] as String,
  vehicleNumber: json['vehicleNumber'] as String,
  driverId: json['driverId'] as String,
  sourceAddress: Points.fromJson(json['sourceAddress'] as Map<String, dynamic>),
  destinationAddress: Points.fromJson(
    json['destinationAddress'] as Map<String, dynamic>,
  ),
  sourceLocation: json['sourceLocation'] as Map<String, dynamic>?,
  destinationLocation: json['destinationLocation'] as Map<String, dynamic>?,
  offeredSeat: (json['offeredSeat'] as num).toInt(),
  currSeats: (json['currSeats'] as num?)?.toInt() ?? 0,
  tripStartDateTime: DateTime.parse(json['tripStartDateTimeUTC'] as String),
  tripTimezone: json['tripTimezone'] as String?,
  routeGeometry: json['routeGeometry'] as Map<String, dynamic>?,
  routeDistance: (json['routeDistance'] as num?)?.toDouble(),
  routeDuration: (json['routeDuration'] as num?)?.toDouble(),
  pricePerKm: (json['pricePerKm'] as num?)?.toDouble(),
  joinedRidersId: json['joinedRidersId'] as List<dynamic>?,
  createdDate: json['createdDate'] == null
      ? null
      : DateTime.parse(json['createdDate'] as String),
);

Map<String, dynamic> _$TripToJson(Trip instance) => <String, dynamic>{
  'tripId': instance.tripId,
  'tripStatus': instance.tripStatus,
  'vehicleNumber': instance.vehicleNumber,
  'driverId': instance.driverId,
  'sourceAddress': instance.sourceAddress,
  'destinationAddress': instance.destinationAddress,
  'sourceLocation': instance.sourceLocation,
  'destinationLocation': instance.destinationLocation,
  'offeredSeat': instance.offeredSeat,
  'currSeats': instance.currSeats,
  'tripStartDateTimeUTC': instance.tripStartDateTime.toIso8601String(),
  'tripTimezone': instance.tripTimezone,
  'routeGeometry': instance.routeGeometry,
  'routeDistance': instance.routeDistance,
  'routeDuration': instance.routeDuration,
  'pricePerKm': instance.pricePerKm,
  'joinedRidersId': instance.joinedRidersId,
  'createdDate': instance.createdDate?.toIso8601String(),
};
