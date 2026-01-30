import 'dart:math';

import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/network/api_response.dart';
import 'package:carsharing/core/network/api_exceptions.dart';
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
      
      final response = await _dioClient.post<ApiResponse<OfferRideResponse>>(
        '/trip-service/api/trips/offer',
        data: jsonData,
        fromJson: (json) {
          print('🚗 DEBUG: Offer Trip Response JSON:');
          print(json);
          
          if (json is Map<String, dynamic>) {
            final result = ApiResponse<OfferRideResponse>.fromJson(
              json,
              (data) {
                print('🚗 DEBUG: Parsing OfferRideResponse from:');
                print(data);
                return OfferRideResponse.fromJson(data as Map<String, dynamic>);
              },
            );
            print('🚗 DEBUG: Trip created with ID: ${result.data?.tripId}');
            return result;
          }
          return ApiResponse<OfferRideResponse>(
            data: OfferRideResponse.fromJson(json as Map<String, dynamic>),
          );
        },
      );
      
      print('🚗 DEBUG: Successfully created trip!');
      return response;
    } catch (e) {
      print('🚗 DEBUG: Error creating trip: $e');
      rethrow;
    }
  }

  /// POST /api/trips/cancel
  /// Cancel an existing trip (driver-initiated)
  /// 
  /// Parameters:
  /// - request: CancelTripRequest with userId, tripId, rideId, optional reason
  /// 
  /// Returns: ApiResponse with success message/status
  /// Throws: ApiException on network/auth/server errors or if error object is present in response
  /// Note: This endpoint returns HTTP 200 even for logical errors, so we check response.error
  Future<ApiResponse<String>> cancelTrip(
    CancelTripRequest request,
  ) async {
    try {
      final response = await _dioClient.post<ApiResponse<String>>(
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
      
      // Check if response contains an error object (HTTP 200 but business logic error)
      if (response.error != null) {
        throw ServerException(
          message: response.error!.message,
          statusCode: 500,
          code: response.error!.code ?? 'BUSINESS_ERROR',
        );
      }
      
      return response;
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
  /// GET /api/trips/active/driver/{driverId}
  /// Get all active trips offered by a driver
  /// 
  /// Parameters:
  /// - driverId: The driver's user ID
  /// 
  /// Returns: ApiResponse with List<DriverTripResponse> with trip details and passenger info
  /// Throws: ApiException on network/auth/server errors
  Future<ApiResponse<List<DriverTripResponse>>> getUpcomingTripsForDriver(
    String driverId,
  ) async {
    try {
      print('🚗 DEBUG: Fetching trips for driver: $driverId');
      
      final response = await _dioClient.get<ApiResponse<List<DriverTripResponse>>>(
        '/trip-service/api/trips/active/driver/$driverId',
        fromJson: (json) {
          print('🚗 DEBUG: Driver trips response:');
          print(json);
          
          if (json is Map<String, dynamic>) {
            final result = ApiResponse<List<DriverTripResponse>>.fromJson(
              json,
              (data) {
                if (data is List) {
                  print('🚗 DEBUG: Found ${data.length} trips for driver');
                  return data
                      .map((item) {
                        print('🚗 DEBUG: Trip: $item');
                        return DriverTripResponse.fromJson(
                            item as Map<String, dynamic>);
                      })
                      .toList();
                }
                return <DriverTripResponse>[];
              },
            );
            return result;
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
      
      return response;
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
          // Backend should return ApiResponseListTrip with data field
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
          
          // Fallback: direct array (legacy)
          if (json is List) {
            final trips = json
                .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                .toList();
            return ApiResponse<List<Trip>>(data: trips);
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
          // Backend should return ApiResponseListTrip with data field
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
          
          // Fallback: direct array (legacy)
          if (json is List) {
            final trips = json
                .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                .toList();
            return ApiResponse<List<Trip>>(data: trips);
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
      // Backend expects these exact parameter names (from OpenAPI spec)
      // Send numbers as actual numbers, not strings
      final queryParams = {
        'sourceLatitude': sourceLat,
        'sourceLongitude': sourceLon,
        'sourceRadiusKm': sourceRadiusKm,
        'destinationLatitude': destLat,
        'destinationLongitude': destLon,
        'destinationRadiusKm': destRadiusKm,
        'earliestDepartureTime': rideStartTime,
        'requestedSeats': requestedSeats,
        'effectiveUserId': effectiveUserId,
      };

      print('🔍 DEBUG: Search Matching Route Request:');
      print('Source: ($sourceLat, $sourceLon) radius: $sourceRadiusKm km');
      print('Destination: ($destLat, $destLon) radius: $destRadiusKm km');
      print('Time: $rideStartTime, Seats: $requestedSeats, User: $effectiveUserId');

      return await _dioClient.get<ApiResponse<List<Trip>>>(
        '/trip-service/api/trips/search/matching-route',
        queryParameters: queryParams,
        fromJson: (json) {
          print('🔍 DEBUG: Search Response JSON:');
          print(json);
          
          // Backend should return ApiResponseListTrip with data field
          if (json is Map<String, dynamic>) {
            final response = ApiResponse<List<Trip>>.fromJson(
              json,
              (data) {
                if (data is List) {
                  final trips = data
                      .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                      .toList();
                  print('🔍 DEBUG: Parsed ${trips.length} trips from response');
                  return trips;
                }
                print('🔍 DEBUG: Data is not a list, returning empty');
                return <Trip>[];
              },
            );
            print('🔍 DEBUG: Final response has ${response.data?.length ?? 0} trips');
            return response;
          }
          
          // Fallback: direct array (legacy)
          if (json is List) {
            print('🔍 DEBUG: Response is direct array with ${json.length} items');
            final trips = json
                .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                .toList();
            return ApiResponse<List<Trip>>(data: trips);
          }

          print('🔍 DEBUG: Unrecognized response format, returning empty');
          return ApiResponse<List<Trip>>(data: const []);
        },
      );
    } catch (e) {
      // WORKAROUND: Backend /matching-route has internal server error (Issue #4)
      // Fall back to two-stage search using working endpoints
      print('⚠️ matching-route failed, using fallback search: $e');
      return await _searchMatchingRouteFallback(
        sourceLat: sourceLat,
        sourceLon: sourceLon,
        sourceRadiusKm: sourceRadiusKm,
        destLat: destLat,
        destLon: destLon,
        destRadiusKm: destRadiusKm,
        requestedSeats: requestedSeats,
      );
    }
  }

  /// Fallback search method when /matching-route endpoint fails
  /// Uses two-stage search: near-source + client-side destination filtering
  Future<ApiResponse<List<Trip>>> _searchMatchingRouteFallback({
    required double sourceLat,
    required double sourceLon,
    required double sourceRadiusKm,
    required double destLat,
    required double destLon,
    required double destRadiusKm,
    required int requestedSeats,
  }) async {
    try {
      // Stage 1: Get trips near source
      final sourceResults = await searchNearSource(
        sourceLat: sourceLat,
        sourceLon: sourceLon,
        radiusKm: sourceRadiusKm,
      );

      final sourceTrips = sourceResults.data ?? [];
      
      if (sourceTrips.isEmpty) {
        return ApiResponse<List<Trip>>(data: const []);
      }

      // Stage 2: Filter by destination proximity and available seats
      final matchingTrips = sourceTrips.where((trip) {
        // Check destination proximity
        final destDistance = _calculateDistance(
          destLat,
          destLon,
          trip.destinationAddress.latitude,
          trip.destinationAddress.longitude,
        );
        
        final withinDestRadius = destDistance <= destRadiusKm;
        
        // Check available seats
        final hasEnoughSeats = trip.availableSeats >= requestedSeats;
        
        return withinDestRadius && hasEnoughSeats;
      }).toList();

      print('🔍 Fallback search: ${sourceTrips.length} near source → ${matchingTrips.length} matching route');
      
      return ApiResponse<List<Trip>>(data: matchingTrips);
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate distance between two coordinates in kilometers using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
