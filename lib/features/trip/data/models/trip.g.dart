// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trip _$TripFromJson(Map<String, dynamic> json) => Trip(
  tripId: json['tripId'] as String?,
  tripStatus: json['tripStatus'] as String?,
  vehicleNumber: json['vehicleNumber'] as String?,
  driverId: json['driverId'] as String?,
  sourceAddress: _parsePoints(json['sourceAddress']),
  destinationAddress: _parsePoints(json['destinationAddress']),
  totalSeats: (json['totalSeats'] as num?)?.toInt() ?? 0,
  bookedSeats: (json['bookedSeats'] as num?)?.toInt() ?? 0,
  availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 0,
  tripStartDateTime: _parseDateTime(json['tripStartDateTimeUTC']),
  tripTimezone: json['tripTimezone'] as String?,
  routeGeometry: json['routeGeometry'] as Map<String, dynamic>?,
  routeDistance: (json['routeDistance'] as num?)?.toDouble(),
  routeDuration: (json['routeDuration'] as num?)?.toDouble(),
  pricePerSeat: (json['pricePerSeat'] as num?)?.toDouble(),
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
  'sourceAddress': _pointsToJson(instance.sourceAddress),
  'destinationAddress': _pointsToJson(instance.destinationAddress),
  'totalSeats': instance.totalSeats,
  'bookedSeats': instance.bookedSeats,
  'availableSeats': instance.availableSeats,
  'tripStartDateTimeUTC': _dateTimeToJson(instance.tripStartDateTime),
  'tripTimezone': instance.tripTimezone,
  'routeGeometry': instance.routeGeometry,
  'routeDistance': instance.routeDistance,
  'routeDuration': instance.routeDuration,
  'pricePerSeat': instance.pricePerSeat,
  'joinedRidersId': instance.joinedRidersId,
  'createdDate': instance.createdDate?.toIso8601String(),
};
