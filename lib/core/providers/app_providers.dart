import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/storage/secure_storage.dart';
import 'package:carsharing/features/trip/data/services/trip_api_service.dart';
import 'package:carsharing/features/trip/data/repositories/trip_repository_impl.dart';
import 'package:carsharing/features/trip/domain/repositories/trip_repository.dart';
import 'package:carsharing/features/booking/data/services/booking_api_service.dart';
import 'package:carsharing/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';

// ============================================================================
// Core Providers - Singleton instances
// ============================================================================

/// Secure storage singleton
/// Use this to access token storage throughout the app
final secureStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// Dio HTTP client singleton
/// Automatically uses TokenStorage for JWT token injection
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

// ============================================================================
// Service Providers - Use REST API
// ============================================================================

/// Trip API Service provider
/// Depends on DioClient
final tripApiServiceProvider = Provider<TripApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return TripApiService(dioClient);
});

/// Booking API Service provider
/// Depends on DioClient
final bookingApiServiceProvider = Provider<BookingApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return BookingApiService(dioClient);
});

// ============================================================================
// Repository Providers - Implement business logic
// ============================================================================

/// Trip Repository provider
/// Uses REST API
final tripRepositoryProvider = Provider<ITripRepository>((ref) {
  final apiService = ref.watch(tripApiServiceProvider);
  return TripRepositoryImpl(apiService);
});

/// Booking Repository provider
/// Uses REST API
final bookingRepositoryProvider = Provider<IBookingRepository>((ref) {
  final apiService = ref.watch(bookingApiServiceProvider);
  return BookingRepositoryImpl(apiService);
});

// ============================================================================
// Query/Mutation Providers - Data fetching & operations
// ============================================================================

/// Search trips matching a route
/// Parameters:
/// - sourceLat, sourceLon: User's starting point
/// - sourceRadiusKm: Search radius around source
/// - destLat, destLon: User's destination
/// - destRadiusKm: Search radius around destination
/// - requestedSeats: Number of seats needed
/// - effectiveUserId: User's ID (to exclude own trips)
final searchMatchingRouteProvider = FutureProvider.family<
    List,
    ({
      double sourceLat,
      double sourceLon,
      double sourceRadiusKm,
      double destLat,
      double destLon,
      double destRadiusKm,
      int requestedSeats,
      String rideStartTime,
      String effectiveUserId,
    })>((ref, params) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.searchMatchingRoute(
    sourceLat: params.sourceLat,
    sourceLon: params.sourceLon,
    sourceRadiusKm: params.sourceRadiusKm,
    destLat: params.destLat,
    destLon: params.destLon,
    destRadiusKm: params.destRadiusKm,
    requestedSeats: params.requestedSeats,
    rideStartTime: params.rideStartTime,
    effectiveUserId: params.effectiveUserId,
  );
});

/// Search trips near a source location
final searchNearSourceProvider = FutureProvider.family<
    List,
    ({
      double lat,
      double lon,
      double radiusKm,
    })>((ref, params) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.searchNearSource(
    sourceLat: params.lat,
    sourceLon: params.lon,
    radiusKm: params.radiusKm,
  );
});

/// Search trips near a destination location
final searchNearDestinationProvider = FutureProvider.family<
    List,
    ({
      double lat,
      double lon,
      double radiusKm,
    })>((ref, params) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.searchNearDestination(
    destLat: params.lat,
    destLon: params.lon,
    radiusKm: params.radiusKm,
  );
});

/// Get upcoming trips for a driver
final getUpcomingTripsForDriverProvider = FutureProvider.family<List, String>(
  (ref, driverId) async {
    final repository = ref.watch(tripRepositoryProvider);
    return repository.getUpcomingTripsForDriver(driverId);
  },
);

/// Get upcoming bookings for a passenger
final getUpcomingBookingsForPassengerProvider =
    FutureProvider.family<List, String>(
  (ref, passengerId) async {
    final repository = ref.watch(bookingRepositoryProvider);
    return repository.getUpcomingBookingsForPassenger(passengerId);
  },
);

/// Local cache for adding new bookings (workaround for backend issue where newly created bookings don't appear in list immediately)
final localBookingsCacheProvider = StateNotifierProvider.family<
    LocalBookingsCacheNotifier,
    List<PassengerRideResponse>,
    String>((ref, passengerId) {
  return LocalBookingsCacheNotifier();
});

class LocalBookingsCacheNotifier extends StateNotifier<List<PassengerRideResponse>> {
  LocalBookingsCacheNotifier() : super([]);

  void addBooking(PassengerRideResponse booking) {
    print('📍 LOCAL CACHE: Adding booking ${booking.rideId} to cache');
    state = [...state, booking];
  }

  void clearCache() {
    state = [];
  }
}
