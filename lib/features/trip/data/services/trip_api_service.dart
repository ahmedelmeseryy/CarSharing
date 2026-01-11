import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/network/api_response.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_response.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';

/// Trip API Service
/// Handles all trip-related endpoints: offer, cancel, search, list upcoming
class TripApiService {
  final DioClient _dioClient;

  TripApiService(this._dioClient);

  /// POST /api/trips/offer
  /// Create a new trip offering
  /// 
  /// Parameters:
  /// - request: OfferRideRequest with driver info, vehicle, source/destination, available seats
  /// 
  /// Returns: ApiResponse with OfferRideResponse
  /// Throws: ApiException on network/auth/server errors
  Future<ApiResponse<OfferRideResponse>> offerTrip(
    OfferRideRequest request,
  ) async {
    try {
      final jsonData = request.toJson();
      print('🚗 DEBUG: Offer Trip Request JSON:');
      print(jsonData);
      
      return await _dioClient.post<ApiResponse<OfferRideResponse>>(
        '/trip-service/api/trips/offer',
        data: jsonData,
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return ApiResponse<OfferRideResponse>.fromJson(
              json,
              (data) => OfferRideResponse.fromJson(data as Map<String, dynamic>),
            );
          }
          return ApiResponse<OfferRideResponse>(
            data: OfferRideResponse.fromJson(json as Map<String, dynamic>),
          );
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/trips/cancel
  /// Cancel an existing trip (driver-initiated)
  /// 
  /// Parameters:
  /// - request: CancelTripRequest with userId, tripId, optional reason
  /// 
  /// Returns: ApiResponse with success message/status
  /// Throws: ApiException on network/auth/server errors
  Future<ApiResponse<String>> cancelTrip(
    CancelTripRequest request,
  ) async {
    try {
      return await _dioClient.post<ApiResponse<String>>(
        '/trip-service/api/trips/cancel',
        data: request.toJson(),
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return ApiResponse<String>.fromJson(
              json,
              (data) => (data ?? 'Trip cancelled').toString(),
            );
          }
          return ApiResponse<String>(data: json.toString());
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/trips/upcoming/driver/{driverId}
  /// Get all upcoming trips for a driver
  /// 
  /// Parameters:
  /// - driverId: UUID of the driver
  /// 
  /// Returns: ApiResponse with List<DriverTripResponse>
  /// Throws: ApiException on network/auth/server errors
  Future<ApiResponse<List<DriverTripResponse>>> getUpcomingTripsForDriver(
    String driverId,
  ) async {
    try {
      return await _dioClient.get<ApiResponse<List<DriverTripResponse>>>(
        '/trip-service/api/trips/upcoming/driver/$driverId',
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return ApiResponse<List<DriverTripResponse>>.fromJson(
              json,
              (data) {
                if (data is List) {
                  return data
                      .map((item) => DriverTripResponse.fromJson(
                          item as Map<String, dynamic>))
                      .toList();
                }
                return <DriverTripResponse>[];
              },
            );
          }

          if (json is List) {
            final trips = json
                .map((item) => DriverTripResponse.fromJson(
                    item as Map<String, dynamic>))
                .toList();
            return ApiResponse<List<DriverTripResponse>>(data: trips);
          }

          return ApiResponse<List<DriverTripResponse>>(data: const []);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/trips/search/near-source
  /// Search for trips near a source location
  /// 
  /// Parameters:
  /// - sourceLat: Latitude of source
  /// - sourceLon: Longitude of source
  /// - radiusKm: Search radius in kilometers (optional, default typically 5)
  /// 
  /// Returns: ApiResponse with List<Trip> matching the source location
  /// Throws: ApiException on network/auth/server errors
  Future<ApiResponse<List<Trip>>> searchNearSource({
    required double sourceLat,
    required double sourceLon,
    double? radiusKm,
  }) async {
    try {
      final queryParams = {
        'latitude': sourceLat,
        'longitude': sourceLon,
        if (radiusKm != null) 'radiusKm': radiusKm,
      };

      return await _dioClient.get<ApiResponse<List<Trip>>>(
        '/trip-service/api/trips/search/near-source',
        queryParameters: queryParams,
        fromJson: (json) {
          // Backend returns direct array, not wrapped
          if (json is List) {
            final trips = json
                .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                .toList();
            return ApiResponse<List<Trip>>(data: trips);
          }
          
          // Fallback: try wrapped response
          if (json is Map<String, dynamic>) {
            return ApiResponse<List<Trip>>.fromJson(
              json,
              (data) {
                if (data is List) {
                  return data
                      .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                      .toList();
                }
                return <Trip>[];
              },
            );
          }

          return ApiResponse<List<Trip>>(data: const []);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/trips/search/near-destination
  /// Search for trips near a destination location
  /// 
  /// Parameters:
  /// - destLat: Latitude of destination
  /// - destLon: Longitude of destination
  /// - radiusKm: Search radius in kilometers (optional)
  /// 
  /// Returns: ApiResponse with List<Trip> matching the destination location
  /// Throws: ApiException on network/auth/server errors
  Future<ApiResponse<List<Trip>>> searchNearDestination({
    required double destLat,
    required double destLon,
    double? radiusKm,
  }) async {
    try {
      final queryParams = {
        'latitude': destLat,
        'longitude': destLon,
        if (radiusKm != null) 'radiusKm': radiusKm,
      };

      return await _dioClient.get<ApiResponse<List<Trip>>>(
        '/trip-service/api/trips/search/near-destination',
        queryParameters: queryParams,
        fromJson: (json) {
          // Backend returns direct array, not wrapped
          if (json is List) {
            final trips = json
                .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                .toList();
            return ApiResponse<List<Trip>>(data: trips);
          }
          
          // Fallback: try wrapped response
          if (json is Map<String, dynamic>) {
            return ApiResponse<List<Trip>>.fromJson(
              json,
              (data) {
                if (data is List) {
                  return data
                      .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                      .toList();
                }
                return <Trip>[];
              },
            );
          }

          return ApiResponse<List<Trip>>(data: const []);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/trips/search/matching-route
  /// Find trips that match both source and destination within radius
  /// This is the most powerful search - finds trips matching the entire route
  /// 
  /// Parameters:
  /// - sourceLat, sourceLon: Passenger's starting point
  /// - sourceRadiusKm: Acceptable radius around source (km)
  /// - destLat, destLon: Passenger's destination
  /// - destRadiusKm: Acceptable radius around destination (km)
  /// - rideStartTime: Preferred start time (ISO format, optional)
  /// - requestedSeats: Number of seats needed (optional)
  /// - effectiveUserId: Passenger ID to exclude own trips (optional)
  /// 
  /// Returns: ApiResponse with List<Trip> with compatible routes
  /// Throws: ApiException on network/auth/server errors
  /// 
  /// Example:
  /// ```dart
  /// final trips = await tripService.searchMatchingRoute(
  ///   sourceLat: 48.8566,
  ///   sourceLon: 2.3522,
  ///   sourceRadiusKm: 2,
  ///   destLat: 48.8606,
  ///   destLon: 2.2945,
  ///   destRadiusKm: 2,
  ///   rideStartTime: '2024-01-15T10:00:00Z',
  ///   requestedSeats: 2,
  ///   effectiveUserId: currentUserId,
  /// );
  /// ```
  Future<ApiResponse<List<Trip>>> searchMatchingRoute({
    required double sourceLat,
    required double sourceLon,
    required double sourceRadiusKm,
    required double destLat,
    required double destLon,
    required double destRadiusKm,
    required String rideStartTime,
    required int requestedSeats,
    required String effectiveUserId,
  }) async {
    try {
      final queryParams = {
        'sourceLat': sourceLat.toString(),
        'sourceLon': sourceLon.toString(),
        'sourceRadiusKm': sourceRadiusKm.toString(),
        'destLat': destLat.toString(),
        'destLon': destLon.toString(),
        'destRadiusKm': destRadiusKm.toString(),
        'rideStartTime': rideStartTime,
        'requestedSeats': requestedSeats.toString(),
        'effectiveUserId': effectiveUserId,
      };

      return await _dioClient.get<ApiResponse<List<Trip>>>(
        '/trip-service/api/trips/search/matching-route',
        queryParameters: queryParams,
        fromJson: (json) {
          // Backend returns direct array, not wrapped
          if (json is List) {
            final trips = json
                .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                .toList();
            return ApiResponse<List<Trip>>(data: trips);
          }
          
          // Fallback: try wrapped response
          if (json is Map<String, dynamic>) {
            return ApiResponse<List<Trip>>.fromJson(
              json,
              (data) {
                if (data is List) {
                  return data
                      .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                      .toList();
                }
                return <Trip>[];
              },
            );
          }

          return ApiResponse<List<Trip>>(data: const []);
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
