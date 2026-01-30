// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverTripResponse _$DriverTripResponseFromJson(
  Map<String, dynamic> json,
) => DriverTripResponse(
  tripId: json['tripId'] as String?,
  driverId: json['driverId'] as String?,
  vehicleNumber: json['vehicleNumber'] as String,
  tripStatus: json['tripStatus'] as String,
  sourceAddress: Points.fromJson(json['sourceAddress'] as Map<String, dynamic>),
  destinationAddress: Points.fromJson(
    json['destinationAddress'] as Map<String, dynamic>,
  ),
  tripStartDateTime: json['tripStartDateTime'] as String,
  tripTimezone: json['tripTimezone'] as String?,
  totalSeats: (json['totalSeats'] as num).toInt(),
  availableSeats: (json['availableSeats'] as num).toInt(),
  bookedSeats: (json['bookedSeats'] as num?)?.toInt() ?? 0,
  passengers: json['passengers'] as List<dynamic>?,
  routeDistanceInKm: (json['routeDistanceInKm'] as num?)?.toDouble(),
  routeDurationInMinutes: (json['routeDurationInMinutes'] as num?)?.toDouble(),
  pricePerKm: (json['pricePerKm'] as num?)?.toDouble(),
);

Map<String, dynamic> _$DriverTripResponseToJson(DriverTripResponse instance) =>
    <String, dynamic>{
      'tripId': instance.tripId,
      'driverId': instance.driverId,
      'vehicleNumber': instance.vehicleNumber,
      'tripStatus': instance.tripStatus,
      'sourceAddress': instance.sourceAddress,
      'destinationAddress': instance.destinationAddress,
      'tripStartDateTime': instance.tripStartDateTime,
      'tripTimezone': instance.tripTimezone,
      'totalSeats': instance.totalSeats,
      'availableSeats': instance.availableSeats,
      'bookedSeats': instance.bookedSeats,
      'passengers': instance.passengers,
      'routeDistanceInKm': instance.routeDistanceInKm,
      'routeDurationInMinutes': instance.routeDurationInMinutes,
      'pricePerKm': instance.pricePerKm,
    };

PassengerRideResponse _$PassengerRideResponseFromJson(
  Map<String, dynamic> json,
) => PassengerRideResponse(
  rideId: json['rideId'] as String?,
  tripId: json['tripId'] as String,
  driverId: json['driverId'] as String,
  vehicleNumber: json['vehicleNumber'] as String?,
  rideStatus: json['rideStatus'] as String,
  pickupLocation: Points.fromJson(
    json['pickupLocation'] as Map<String, dynamic>,
  ),
  dropoffLocation: Points.fromJson(
    json['dropoffLocation'] as Map<String, dynamic>,
  ),
  bookedSeats: (json['bookedSeats'] as num).toInt(),
  estimatedFare: (json['estimatedFare'] as num?)?.toDouble(),
  tripStartDateTime: json['tripStartDateTime'] as String,
);

Map<String, dynamic> _$PassengerRideResponseToJson(
  PassengerRideResponse instance,
) => <String, dynamic>{
  'rideId': instance.rideId,
  'tripId': instance.tripId,
  'driverId': instance.driverId,
  'vehicleNumber': instance.vehicleNumber,
  'rideStatus': instance.rideStatus,
  'pickupLocation': instance.pickupLocation,
  'dropoffLocation': instance.dropoffLocation,
  'bookedSeats': instance.bookedSeats,
  'estimatedFare': instance.estimatedFare,
  'tripStartDateTime': instance.tripStartDateTime,
};
