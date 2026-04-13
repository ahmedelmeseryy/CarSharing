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
    final response = await _bookingApiService.joinTrip(request);
    if (response.data == null) {
      // Backend returns null data with success message when booking succeeds
      // Return a placeholder response so the UI knows it succeeded
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
    try {
      final response = await _bookingApiService.getUpcomingBookingsForPassenger(passengerId);
      
      final result = response.data ?? <PassengerRideResponse>[];
      return result;
    } catch (e) {
      
      // Handle 404 - endpoint not implemented on backend yet
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        return <PassengerRideResponse>[];
      }
      
      rethrow;
    }
  }
}
