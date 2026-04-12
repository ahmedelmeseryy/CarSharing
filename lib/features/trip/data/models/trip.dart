import 'package:json_annotation/json_annotation.dart';
import 'points.dart';

part 'trip.g.dart';

// ── Custom fromJson helpers ────────────────────────────────────────────────

Points _parsePoints(dynamic v) {
  if (v == null) return const Points(latitude: 0, longitude: 0);
  if (v is Map<String, dynamic>) return Points.fromJson(v);
  return const Points(latitude: 0, longitude: 0);
}

Map<String, dynamic> _pointsToJson(Points p) => p.toJson();

DateTime _parseDateTime(dynamic v) {
  if (v == null) return DateTime.now();
  try {
    return DateTime.parse(v as String);
  } catch (_) {
    return DateTime.now();
  }
}

String _dateTimeToJson(DateTime d) => d.toIso8601String();

// ── Model ──────────────────────────────────────────────────────────────────

/// Represents a Trip when searching for available trips.
/// Server returns: tripId, driverId, status, departureTime,
///   sourceLocation, destinationLocation, availableSeats, pricePerSeat
@JsonSerializable()
class Trip {
  final String? tripId;

  final String? tripStatus;

  final String? vehicleNumber;
  final String? driverId;

  @JsonKey(name: 'sourceAddress', fromJson: _parsePoints, toJson: _pointsToJson)
  final Points sourceAddress;

  @JsonKey(name: 'destinationAddress', fromJson: _parsePoints, toJson: _pointsToJson)
  final Points destinationAddress;

  @JsonKey(defaultValue: 0)
  final int totalSeats;

  @JsonKey(defaultValue: 0)
  final int bookedSeats;

  @JsonKey(defaultValue: 0)
  final int availableSeats;

  @JsonKey(name: 'tripStartDateTimeUTC', fromJson: _parseDateTime, toJson: _dateTimeToJson)
  final DateTime tripStartDateTime;

  @JsonKey(name: 'tripTimezone')
  final String? tripTimezone;

  @JsonKey(name: 'routeGeometry')
  final Map<String, dynamic>? routeGeometry;

  @JsonKey(name: 'routeDistance')
  final double? routeDistance;

  @JsonKey(name: 'routeDuration')
  final double? routeDuration;

  @JsonKey(name: 'pricePerSeat')
  final double? pricePerSeat;

  @JsonKey(name: 'joinedRidersId')
  final List<dynamic>? joinedRidersId;

  @JsonKey(name: 'createdDate')
  final DateTime? createdDate;

  Trip({
    this.tripId,
    this.tripStatus,
    this.vehicleNumber,
    this.driverId,
    required this.sourceAddress,
    required this.destinationAddress,
    this.totalSeats = 0,
    this.bookedSeats = 0,
    this.availableSeats = 0,
    required this.tripStartDateTime,
    this.tripTimezone,
    this.routeGeometry,
    this.routeDistance,
    this.routeDuration,
    this.pricePerSeat,
    this.joinedRidersId,
    this.createdDate,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
  Map<String, dynamic> toJson() => _$TripToJson(this);

  /// Flat price per seat (€). Returns 0 if not set.
  double get estimatedFare => pricePerSeat ?? 0;

  /// Available seats — uses the API field when present, otherwise derives from totalSeats - bookedSeats.
  /// The backend often omits availableSeats from search responses.
  int get freeSeats {
    if (availableSeats > 0) return availableSeats;
    return (totalSeats - bookedSeats).clamp(0, totalSeats);
  }

  @override
  String toString() =>
      'Trip($tripId: ${sourceAddress.placeAddress} → ${destinationAddress.placeAddress})';
}
