import 'package:carsharing/features/booking/data/services/booking_api_service.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';
import 'package:carsharing/features/trip/domain/repositories/trip_repository.dart';

/// Booking Repository Implementation
/// Uses REST API for all operations
class BookingRepositoryImpl implements IBookingRepository {
  final BookingApiService _bookingApiService;

  BookingRepositoryImpl(this._bookingApiService);

  @override
  Future<PassengerRideResponse> joinTrip(JoinTripRequest request) async {
    print('📍 BOOKING REPO: joinTrip called with tripId: ${request.tripId}');
    final response = await _bookingApiService.joinTrip(request);
    print('📍 BOOKING REPO: joinTrip API response: $response');
    print('📍 BOOKING REPO: joinTrip response data: ${response.data}');
    if (response.data == null) {
      throw Exception('Failed to join trip: ${response.message}');
    }
    print('✅ BOOKING REPO: joinTrip successful, booking rideId: ${response.data!.rideId}');
    return response.data!;
  }

  @override
  Future<String> cancelBooking(CancelTripRequest request) async {
    final response = await _bookingApiService.cancelBooking(request);
    if (response.data == null) {
      throw Exception('Failed to cancel booking: ${response.message}');
    }
    return response.data!;
  }

  @override
  Future<List<PassengerRideResponse>> getUpcomingBookingsForPassenger(
    String passengerId,
  ) async {
    print('📍 BOOKING REPO: Requesting bookings for passengerId: $passengerId');
    try {
      final response = await _bookingApiService.getUpcomingBookingsForPassenger(passengerId);
      print('📍 BOOKING REPO: Raw API response: $response');
      print('📍 BOOKING REPO: Response type: ${response.runtimeType}');
      print('📍 BOOKING REPO: Response data: ${response.data}');
      print('📍 BOOKING REPO: Response data type: ${response.data?.runtimeType}');
      print('📍 BOOKING REPO: Response data length: ${response.data?.length ?? 0}');
      print('📍 BOOKING REPO: Response message: ${response.message}');
      print('📍 BOOKING REPO: Response error: ${response.error}');
      
      final result = response.data ?? <PassengerRideResponse>[];
      print('📍 BOOKING REPO: Returning ${result.length} bookings');
      return result;
    } catch (e, st) {
      print('❌ BOOKING REPO: Exception: $e');
      print('❌ BOOKING REPO: Stack: $st');
      rethrow;
    }
  }
}
