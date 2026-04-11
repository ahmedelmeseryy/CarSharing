// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_ride_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfferRideRequest _$OfferRideRequestFromJson(Map<String, dynamic> json) =>
    OfferRideRequest(
      driverId: json['driverId'] as String,
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
      pricePerSeat: (json['pricePerSeat'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$OfferRideRequestToJson(OfferRideRequest instance) =>
    <String, dynamic>{
      'driverId': instance.driverId,
      'sourceAddress': const PointsConverter().toJson(instance.sourceAddress),
      'destinationAddress': const PointsConverter().toJson(
        instance.destinationAddress,
      ),
      'tripStartDateTime': const DateTimeConverter().toJson(
        instance.tripStartDateTime,
      ),
      'totalSeats': instance.totalSeats,
      if (instance.pricePerSeat case final value?) 'pricePerSeat': value,
    };
