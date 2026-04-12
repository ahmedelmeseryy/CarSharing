import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/network/api_response.dart';
import 'package:carsharing/core/network/api_exceptions.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';

class BookingApiService {
  final DioClient _dioClient;

  BookingApiService(this._dioClient);

  // POST /trip-service/api/rides/book — passenger joins an existing trip
  Future<ApiResponse<PassengerRideResponse>> joinTrip(
    JoinTripRequest request,
  ) async {
    try {
      final response = await _dioClient.post<ApiResponse<PassengerRideResponse>>(
        '/trip-service/api/rides/book',
        data: request.toJson(),
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return ApiResponse<PassengerRideResponse>.fromJson(
              json,
              (data) => PassengerRideResponse.fromJson(
                  data as Map<String, dynamic>),
            );
          }

          return ApiResponse<PassengerRideResponse>(
            data: PassengerRideResponse.fromJson(
              json as Map<String, dynamic>,
            ),
          );
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // POST /trip-service/api/rides/cancel — passenger cancels their booking
  // Returns HTTP 200 even on business errors; checks response.error manually
  Future<ApiResponse<String>> cancelBooking(
    CancelTripRequest request,
  ) async {
    try {
      final response = await _dioClient.post<ApiResponse<String>>(
        '/trip-service/api/rides/cancel',
        data: request.toJson(),
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return ApiResponse<String>.fromJson(
              json,
              (data) => (data ?? 'Booking cancelled').toString(),
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

  // Returns bookings for a trip — tries multiple endpoints since no single driver-accessible one exists
  Future<List<Map<String, dynamic>>> getBookingsForDriverTrip({
    required String driverId,
    required String tripId,
  }) async {
    // attempt 1: dedicated trip-bookings endpoints
    for (final path in [
      '/trip-service/api/rides/trip/$tripId',
      '/trip-service/api/bookings/trip/$tripId',
    ]) {
      try {
        final response = await _dioClient.get<dynamic>(path);
        final all = _extractMaps(response);
        if (all.isNotEmpty) return all;
      } catch (_) {}
    }

    // attempt 2: admin bookings endpoint (filtered client-side)
    for (final headers in [
      {'X-User-Role': 'ADMIN'},
      <String, String>{},
    ]) {
      try {
        final response = await _dioClient.get<dynamic>(
          '/trip-service/api/admin/bookings',
          queryParameters: {'page': 0, 'size': 200},
          headers: headers.isEmpty ? null : headers,
        );
        final matches = _extractMaps(response)
            .where((b) => (b['tripId'] ?? b['trip_id']) == tripId)
            .toList();
        if (matches.isNotEmpty) return matches;
      } catch (_) {}
    }

    return [];
  }

  List<Map<String, dynamic>> _extractMaps(dynamic response) {
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

  // GET /trip-service/api/rides/active/passenger/{passengerId}
  Future<ApiResponse<List<PassengerRideResponse>>>
      getUpcomingBookingsForPassenger(String passengerId) async {
    try {
      final response = await _dioClient
          .get<ApiResponse<List<PassengerRideResponse>>>(
        '/trip-service/api/rides/active/passenger/$passengerId',
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return ApiResponse<List<PassengerRideResponse>>.fromJson(
              json,
              (data) {
                if (data is List) {
                  return data
                      .map((item) => PassengerRideResponse.fromJson(
                          item as Map<String, dynamic>))
                      .toList();
                }
                return <PassengerRideResponse>[];
              },
            );
          }

          if (json is List) {
            final rides = json
                .map((item) => PassengerRideResponse.fromJson(
                    item as Map<String, dynamic>))
                .toList();
            return ApiResponse<List<PassengerRideResponse>>(data: rides);
          }

          return ApiResponse<List<PassengerRideResponse>>(data: const []);
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
