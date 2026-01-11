import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_response.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';

/// Trip Repository Interface
/// Abstracts all trip-related business operations
abstract class ITripRepository {
  /// Create a new trip offer
  /// Throws ApiException on failure
  Future<OfferRideResponse> offerTrip(OfferRideRequest request);

  /// Cancel an existing trip
  /// Throws ApiException on failure
  Future<String> cancelTrip(CancelTripRequest request);

  /// Get all upcoming trips for a driver
  /// Throws ApiException on failure
  Future<List<DriverTripResponse>> getUpcomingTripsForDriver(String driverId);

  /// Search for trips near a source location
  /// Throws ApiException on failure
  Future<List<Trip>> searchNearSource({
    required double sourceLat,
    required double sourceLon,
    double? radiusKm,
  });

  /// Search for trips near a destination location
  /// Throws ApiException on failure
  Future<List<Trip>> searchNearDestination({
    required double destLat,
    required double destLon,
    double? radiusKm,
  });

  /// Search for trips matching both source and destination
  /// Best option for passenger route matching
  /// Throws ApiException on failure
  Future<List<Trip>> searchMatchingRoute({
    required double sourceLat,
    required double sourceLon,
    required double sourceRadiusKm,
    required double destLat,
    required double destLon,
    required double destRadiusKm,
    required String rideStartTime,
    required int requestedSeats,
    required String effectiveUserId,
  });
}

/// Booking Repository Interface
/// Abstracts all booking-related business operations
abstract class IBookingRepository {
  /// Join an existing trip as a passenger
  /// Throws ApiException on failure
  Future<PassengerRideResponse> joinTrip(JoinTripRequest request);

  /// Cancel a passenger booking
  /// Throws ApiException on failure
  Future<String> cancelBooking(CancelTripRequest request);

  /// Get all upcoming bookings for a passenger
  /// Throws ApiException on failure
  Future<List<PassengerRideResponse>> getUpcomingBookingsForPassenger(
    String passengerId,
  );
}
