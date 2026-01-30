// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_ride_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfferRideRequest _$OfferRideRequestFromJson(Map<String, dynamic> json) =>
    OfferRideRequest(
      driverId: json['driverId'] as String,
      vehicleNumber: json['vehicleNumber'] as String,
      sourceAddress: const PointsConverter().fromJson(
        json['sourceAddress'] as Map<String, dynamic>,
      ),
      destinationAddress: const PointsConverter().fromJson(
        json['destinationAddress'] as Map<String, dynamic>,
      ),
      tripStartDateTime: const DateTimeConverter().fromJson(
        json['tripStartDateTime'] as String,
      ),
      totalSeats: (json['totalSeats'] as num).toInt(),
    );

Map<String, dynamic> _$OfferRideRequestToJson(OfferRideRequest instance) =>
    <String, dynamic>{
      'driverId': instance.driverId,
      'vehicleNumber': instance.vehicleNumber,
      'sourceAddress': const PointsConverter().toJson(instance.sourceAddress),
      'destinationAddress': const PointsConverter().toJson(
        instance.destinationAddress,
      ),
      'tripStartDateTime': const DateTimeConverter().toJson(
        instance.tripStartDateTime,
      ),
      'totalSeats': instance.totalSeats,
    };
