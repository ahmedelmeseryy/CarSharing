// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Points _$PointsFromJson(Map<String, dynamic> json) => Points(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  placeId: json['placeId'] as String?,
  placeAddress: json['placeAddress'] as String?,
);

Map<String, dynamic> _$PointsToJson(Points instance) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  if (instance.placeId case final value?) 'placeId': value,
  if (instance.placeAddress case final value?) 'placeAddress': value,
};
