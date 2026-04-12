import 'dart:math';

import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/network/api_response.dart';
import 'package:carsharing/core/network/api_exceptions.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_response.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';

class TripApiService {
  final DioClient _dioClient;

  TripApiService(this._dioClient);

  // POST /trip-service/api/trips/offer — driver creates a new trip
  Future<ApiResponse<OfferRideResponse>> offerTrip(
    OfferRideRequest request,
  ) async {
    try {
      final jsonData = request.toJson();
      
      final response = await _dioClient.post<ApiResponse<OfferRideResponse>>(
        '/trip-service/api/trips/offer',
        data: jsonData,
        fromJson: (json) {
          
          if (json is Map<String, dynamic>) {
            final result = ApiResponse<OfferRideResponse>.fromJson(
              json,
              (data) {
                return OfferRideResponse.fromJson(data as Map<String, dynamic>);
              },
            );
            return result;
          }
          return ApiResponse<OfferRideResponse>(
            data: OfferRideResponse.fromJson(json as Map<String, dynamic>),
          );
        },
      );
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // POST /trip-service/api/trips/cancel — driver cancels their trip
  // Returns HTTP 200 even on business errors; checks response.error manually
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

  // GET /trip-service/api/trips/active/driver/{driverId}
  Future<ApiResponse<List<DriverTripResponse>>> getUpcomingTripsForDriver(
    String driverId,
  ) async {
    try {

      final response = await _dioClient.get<ApiResponse<List<DriverTripResponse>>>(
        '/trip-service/api/trips/active/driver/$driverId',
        fromJson: (json) {
          
          if (json is Map<String, dynamic>) {
            final result = ApiResponse<List<DriverTripResponse>>.fromJson(
              json,
              (data) {
                if (data is List) {
                  return data
                      .map((item) {
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

  // GET /trip-service/api/trips/{tripId} — returns trip metadata (no passenger list)
  Future<Map<String, dynamic>?> getTripById(String tripId) async {
    try {
      final response = await _dioClient.get<dynamic>(
        '/trip-service/api/trips/$tripId',
      );
      if (response is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // GET /trip-service/api/trips/search/near-source
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

  // GET /trip-service/api/trips/search/near-destination
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

  // GET /trip-service/api/trips/search/matching-route — finds trips matching both source and destination
  // Falls back to two-stage search if endpoint fails (see WORKAROUND below)
  Future<ApiResponse<List<Trip>>> searchMatchingRoute({
    required double sourceLat,
    required double sourceLon,
    required double sourceRadiusKm,
    required double destLat,
    required double destLon,
    required double destRadiusKm,
    required String rideStartTime,
    required int requestedSeats,
    required String effectiveUserId, // passenger's own ID — excludes their trips from results
  }) async {
    try {
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

      return await _dioClient.get<ApiResponse<List<Trip>>>(
        '/trip-service/api/trips/search/matching-route',
        queryParameters: queryParams,
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            final response = ApiResponse<List<Trip>>.fromJson(
              json,
              (data) {
                if (data is List) {
                  final trips = data
                      .map((item) => Trip.fromJson(item as Map<String, dynamic>))
                      .toList();
                  return trips;
                }
                return <Trip>[];
              },
            );
            return response;
          }

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
      // WORKAROUND: Backend /matching-route has internal server error (Issue #4)
      // Fall back to two-stage search using working endpoints
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

  // Fallback: fetch trips near source, then filter client-side by destination radius and seat count
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
      final sourceResults = await searchNearSource(
        sourceLat: sourceLat,
        sourceLon: sourceLon,
        radiusKm: sourceRadiusKm,
      );

      final sourceTrips = sourceResults.data ?? [];
      
      if (sourceTrips.isEmpty) {
        return ApiResponse<List<Trip>>(data: const []);
      }

      final matchingTrips = sourceTrips.where((trip) {
        final destDistance = _calculateDistance(
          destLat,
          destLon,
          trip.destinationAddress.latitude,
          trip.destinationAddress.longitude,
        );
        return destDistance <= destRadiusKm && trip.availableSeats >= requestedSeats;
      }).toList();

      return ApiResponse<List<Trip>>(data: matchingTrips);
    } catch (e) {
      rethrow;
    }
  }

  // Haversine formula — returns distance in km
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

  static const _adminHeaders = {'X-User-Role': 'ADMIN'}; // required for all /admin/* endpoints

  // GET /trip-service/api/admin/trips/upcoming — paginated
  Future<Map<String, dynamic>> adminListUpcomingTrips({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dioClient.get<dynamic>(
      '/trip-service/api/admin/trips/upcoming',
      queryParameters: {'page': page, 'size': size},
      headers: _adminHeaders,
    );
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is List) return {'content': data, 'totalElements': data.length, 'totalPages': 1};
    }
    return {'content': [], 'totalElements': 0, 'totalPages': 0};
  }

  // GET /trip-service/api/admin/trips — paginated
  Future<Map<String, dynamic>> adminListAllTrips({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dioClient.get<dynamic>(
      '/trip-service/api/admin/trips',
      queryParameters: {'page': page, 'size': size},
      headers: _adminHeaders,
    );
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is List) return {'content': data, 'totalElements': data.length, 'totalPages': 1};
    }
    return {'content': [], 'totalElements': 0, 'totalPages': 0};
  }

  // GET /trip-service/api/admin/trips/{tripId} — full trip detail including bookings
  Future<Map<String, dynamic>?> adminGetTrip(String tripId) async {
    try {
      final response = await _dioClient.get<dynamic>(
        '/trip-service/api/admin/trips/$tripId',
        headers: _adminHeaders,
      );
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is Map<String, dynamic>) return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Returns all trips for a driver; tries driver-specific endpoint first, falls back to filtering all trips
  Future<List<Map<String, dynamic>>> adminGetTripsByDriver(String driverId) async {
    try {
      for (final path in [
        '/trip-service/api/admin/trips/driver/$driverId',
        '/trip-service/api/trips/active/driver/$driverId',
      ]) {
        try {
          final r = await _dioClient.get<dynamic>(path, headers: _adminHeaders);
          final list = _extractAdminList(r);
          if (list.isNotEmpty) return list;
        } catch (_) {}
      }
      // Fallback: fetch all and filter
      final response = await _dioClient.get<dynamic>(
        '/trip-service/api/admin/trips',
        queryParameters: {'page': 0, 'size': 500},
        headers: _adminHeaders,
      );
      return _extractAdminList(response)
          .where((t) =>
              (t['driverId'] ?? t['driver_id']) == driverId)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // DELETE /trip-service/api/admin/trips/{tripId} — falls back to cancel endpoint if delete fails
  Future<void> adminDeleteTrip(String tripId) async {
    try {
      await _dioClient.delete<dynamic>(
        '/trip-service/api/admin/trips/$tripId',
        headers: _adminHeaders,
      );
    } catch (_) {
      try {
        await _dioClient.post<dynamic>(
          '/trip-service/api/admin/trips/$tripId/cancel',
          headers: _adminHeaders,
        );
      } catch (_) {}
    }
  }

  List<Map<String, dynamic>> _extractAdminList(dynamic response) {
    List<dynamic> raw = [];
    if (response is List) {
      raw = response;
    } else if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        raw = data;
      } else if (data is Map<String, dynamic>) {
        final content = data['content'];
        if (content is List) raw = content;
      }
    }
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  // GET /trip-service/api/admin/bookings — loads all bookings and filters by tripId client-side
  Future<List<Map<String, dynamic>>> adminGetBookingsForTrip(String tripId) async {
    try {
      final response = await _dioClient.get<dynamic>(
        '/trip-service/api/admin/bookings',
        queryParameters: {'page': 0, 'size': 100},
        headers: _adminHeaders,
      );
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        List<dynamic> all = [];
        if (data is Map<String, dynamic>) {
          all = data['content'] is List ? data['content'] as List : [];
        } else if (data is List) {
          all = data;
        }
        return all
            .whereType<Map<String, dynamic>>()
            .where((b) => b['tripId'] == tripId)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
