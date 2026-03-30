import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/network/api_response.dart';
import 'package:carsharing/core/network/api_exceptions.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';

/// Booking API Service
/// Handles booking-related endpoints: join trip, cancel booking, list upcoming bookings
class BookingApiService {
  final DioClient _dioClient;

  BookingApiService(this._dioClient);

  /// POST /api/bookings/join
  /// Passenger joins an existing trip
  /// 
  /// Parameters:
  /// - request: JoinTripRequest with trip ID, passenger info, pickup/dropoff, seats
  /// 
  /// Returns: ApiResponse with PassengerRideResponse (booking confirmation)
  /// Throws: ApiException on network/auth/server errors or if trip full/invalid
  /// 
  /// Common Status Codes:
  /// - 201: Booking created successfully
  /// - 400: Invalid request (missing seats, trip full, etc.)
  /// - 404: Trip not found
  /// - 409: Passenger already joined this trip
  /// 
  /// Example:
  /// ```dart
  /// final booking = await bookingService.joinTrip(
  ///   JoinTripRequest(
  ///     tripId: 'trip-123',
  ///     passengerId: userId,
  ///     driverId: 'driver-456',
  ///     pickupPoint: Points(latitude: 48.8566, longitude: 2.3522),
  ///     destinationPoint: Points(latitude: 48.8606, longitude: 2.2945),
  ///     rideStartTime: '2024-01-15T10:00:00Z',
  ///     requestedSeats: 2,
  ///   ),
  /// );
  /// ```
  Future<ApiResponse<PassengerRideResponse>> joinTrip(
    JoinTripRequest request,
  ) async {
    try {
      print('🔵 BOOKING API: joinTrip called with tripId=${request.tripId}, passengerId=${request.passengerId}');
      final response = await _dioClient.post<ApiResponse<PassengerRideResponse>>(
        '/trip-service/api/rides/book',
        data: request.toJson(),
        fromJson: (json) {
          print('📦 BOOKING API: joinTrip raw response: $json');
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
      print('🟢 BOOKING API: joinTrip response: ${response.data?.rideId}');
      return response;
    } catch (e) {
      print('❌ BOOKING API: joinTrip error: $e');
      rethrow;
    }
  }

  /// POST /api/bookings/cancel
  /// Passenger cancels an existing booking
  /// 
  /// Parameters:
  /// - request: CancelTripRequest with userId, tripId, rideId, optional reason
  /// 
  /// Returns: ApiResponse with cancellation confirmation/status
  /// Throws: ApiException on network/auth/server errors or if error object is present in response
  /// Note: This endpoint returns HTTP 200 even for logical errors, so we check response.error
  /// 
  /// Common Status Codes:
  /// - 200: Booking cancelled successfully
  /// - 400: Cannot cancel (already completed, too late, etc.)
  /// - 404: Booking not found
  /// 
  /// Example:
  /// ```dart
  /// await bookingService.cancelBooking(
  ///   CancelTripRequest(
  ///     userId: currentUserId,
  ///     tripId: 'trip-123',
  ///     rideId: 'ride-789',
  ///     cancellationReason: 'Plans changed',
  ///   ),
  /// );
  /// ```
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

  /// GET /api/bookings/active/passenger/{passengerId}
  /// Get all active bookings for a passenger
  /// 
  /// Parameters:
  /// - passengerId: UUID of the passenger
  /// 
  /// Returns: ApiResponse with List<PassengerRideResponse> for active rides
  /// Throws: ApiException on network/auth/server errors
  /// 
  /// Note: "Active" typically means:
  /// - Status = pending or confirmed
  /// - Trip start time > now
  /// - Not cancelled
  /// 
  /// Example:
  /// ```dart
  /// final activeRides = await bookingService.getUpcomingBookingsForPassenger(
  ///   userId,
  /// );
  /// 
  /// for (var ride in activeRides.data ?? []) {
  ///   print('Riding with driver ${ride.driverId} on ${ride.tripStartDateTime}');
  /// }
  /// ```
  Future<ApiResponse<List<PassengerRideResponse>>>
      getUpcomingBookingsForPassenger(String passengerId) async {
    try {
      print('🔵 BOOKING API: Fetching bookings for passenger: $passengerId');
      final response = await _dioClient
          .get<ApiResponse<List<PassengerRideResponse>>>(
        '/trip-service/api/rides/active/passenger/$passengerId',
        fromJson: (json) {
          print('📦 BOOKING API: Raw response: $json');
          if (json is Map<String, dynamic>) {
            return ApiResponse<List<PassengerRideResponse>>.fromJson(
              json,
              (data) {
                print('📋 BOOKING API: Parsed data: $data');
                if (data is List) {
                  print('✅ BOOKING API: Data is list with ${data.length} items');
                  return data
                      .map((item) => PassengerRideResponse.fromJson(
                          item as Map<String, dynamic>))
                      .toList();
                }
                print('⚠️ BOOKING API: Data is not a list, returning empty');
                return <PassengerRideResponse>[];
              },
            );
          }

          if (json is List) {
            print('✅ BOOKING API: Response is direct list with ${json.length} items');
            final rides = json
                .map((item) => PassengerRideResponse.fromJson(
                    item as Map<String, dynamic>))
                .toList();
            return ApiResponse<List<PassengerRideResponse>>(data: rides);
          }

          print('⚠️ BOOKING API: Unexpected response format');
          return ApiResponse<List<PassengerRideResponse>>(data: const []);
        },
      );
      print('🟢 BOOKING API: Final response data: ${response.data}');
      return response;
    } catch (e) {
      print('❌ BOOKING API: Error: $e');
      rethrow;
    }
  }
}
