// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinTripRequest _$JoinTripRequestFromJson(Map<String, dynamic> json) =>
    JoinTripRequest(
      tripId: json['tripId'] as String,
      passengerId: json['passengerId'] as String,
      driverId: json['driverId'] as String,
      pickupPoint: const PointsConverter().fromJson(
        json['pickupPoint'] as Map<String, dynamic>,
      ),
      destinationPoint: const PointsConverter().fromJson(
        json['destinationPoint'] as Map<String, dynamic>,
      ),
      rideStartTime: json['rideStartTime'] as String,
      requestedSeats: (json['requestedSeats'] as num).toInt(),
    );

Map<String, dynamic> _$JoinTripRequestToJson(
  JoinTripRequest instance,
) => <String, dynamic>{
  'tripId': instance.tripId,
  'passengerId': instance.passengerId,
  'driverId': instance.driverId,
  'pickupPoint': const PointsConverter().toJson(instance.pickupPoint),
  'destinationPoint': const PointsConverter().toJson(instance.destinationPoint),
  'rideStartTime': instance.rideStartTime,
  'requestedSeats': instance.requestedSeats,
};

CancelTripRequest _$CancelTripRequestFromJson(Map<String, dynamic> json) =>
    CancelTripRequest(
      userId: json['userId'] as String,
      tripId: json['tripId'] as String,
      rideId: json['rideId'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
    );

Map<String, dynamic> _$CancelTripRequestToJson(CancelTripRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'tripId': instance.tripId,
      if (instance.rideId case final value?) 'rideId': value,
      if (instance.cancellationReason case final value?)
        'cancellationReason': value,
    };
