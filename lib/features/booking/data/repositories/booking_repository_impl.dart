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
      // Backend returns null data with success message when booking succeeds
      // Return a placeholder response so the UI knows it succeeded
      print('✅ BOOKING REPO: joinTrip successful (null data), message: ${response.message}');
      return PassengerRideResponse(
        rideId: 'booking-${DateTime.now().millisecondsSinceEpoch}',
        tripId: request.tripId,
        driverId: request.driverId,
        rideStatus: 'CONFIRMED',
        pickupLocation: request.pickupPoint,
        dropoffLocation: request.destinationPoint,
        bookedSeats: request.requestedSeats,
        tripStartDateTime: request.rideStartTime,
      );
    }
    print('✅ BOOKING REPO: joinTrip successful, booking rideId: ${response.data!.rideId}');
    return response.data!;
  }

  @override
  Future<String> cancelBooking(CancelTripRequest request) async {
    final response = await _bookingApiService.cancelBooking(request);
    
    // Check if response contains an error object (HTTP 200 but business logic error)
    if (response.error != null) {
      throw Exception('Booking cancellation failed: ${response.error!.message}');
    }
    
    if (response.data == null) {
      return response.message ?? 'Booking cancelled successfully';
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
      
      // Handle 404 - endpoint not implemented on backend yet
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ BOOKING REPO: Backend endpoint not available (404), returning empty list');
        return <PassengerRideResponse>[];
      }
      
      rethrow;
    }
  }
}
