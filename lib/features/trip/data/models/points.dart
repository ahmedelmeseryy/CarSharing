import 'package:json_annotation/json_annotation.dart';

part 'points.g.dart';

/// Represents a geographical point with address details
/// Maps from Swagger: Points object
@JsonSerializable(includeIfNull: false)
class Points {
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? placeAddress;

  const Points({
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.placeAddress,
  });

  factory Points.fromJson(Map<String, dynamic> json) => _$PointsFromJson(json);
  Map<String, dynamic> toJson() => _$PointsToJson(this);

  @override
  String toString() => 'Points(lat: $latitude, lon: $longitude, address: $placeAddress)';
}
