import 'package:carsharing/features/trip/data/services/trip_api_service.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_response.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';
import 'package:carsharing/features/trip/domain/repositories/trip_repository.dart';

/// Trip Repository Implementation
/// Uses REST API for all operations
class TripRepositoryImpl implements ITripRepository {
  final TripApiService _tripApiService;

  TripRepositoryImpl(this._tripApiService);

  @override
  Future<OfferRideResponse> offerTrip(OfferRideRequest request) async {
    final response = await _tripApiService.offerTrip(request);
    if (response.data == null) {
      throw Exception('Failed to offer trip: ${response.message}');
    }
    return response.data!;
  }

  @override
  Future<String> cancelTrip(CancelTripRequest request) async {
    await _tripApiService.cancelTrip(request);
    return 'Trip cancelled successfully';
  }

  @override
  Future<List<DriverTripResponse>> getUpcomingTripsForDriver(
    String driverId,
  ) async {
    final response = await _tripApiService.getUpcomingTripsForDriver(driverId);
    return response.data ?? <DriverTripResponse>[];
  }

  @override
  Future<List<Trip>> searchNearSource({
    required double sourceLat,
    required double sourceLon,
    double? radiusKm,
  }) async {
    final response = await _tripApiService.searchNearSource(
      sourceLat: sourceLat,
      sourceLon: sourceLon,
      radiusKm: radiusKm,
    );
    return response.data ?? <Trip>[];
  }

  @override
  Future<List<Trip>> searchNearDestination({
    required double destLat,
    required double destLon,
    double? radiusKm,
  }) async {
    final response = await _tripApiService.searchNearDestination(
      destLat: destLat,
      destLon: destLon,
      radiusKm: radiusKm,
    );
    return response.data ?? <Trip>[];
  }

  @override
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
  }) async {
    final response = await _tripApiService.searchMatchingRoute(
      sourceLat: sourceLat,
      sourceLon: sourceLon,
      sourceRadiusKm: sourceRadiusKm,
      destLat: destLat,
      destLon: destLon,
      destRadiusKm: destRadiusKm,
      rideStartTime: rideStartTime,
      requestedSeats: requestedSeats,
      effectiveUserId: effectiveUserId,
    );
    return response.data ?? <Trip>[];
  }
}
