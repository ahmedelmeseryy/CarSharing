import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/storage/secure_storage.dart';
import 'package:carsharing/features/trip/data/services/trip_api_service.dart';
import 'package:carsharing/features/trip/data/repositories/trip_repository_impl.dart';
import 'package:carsharing/features/trip/domain/repositories/trip_repository.dart';
import 'package:carsharing/features/booking/data/services/booking_api_service.dart';
import 'package:carsharing/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';

// Core singletons
final secureStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

// API services
final tripApiServiceProvider = Provider<TripApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return TripApiService(dioClient);
});

final bookingApiServiceProvider = Provider<BookingApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return BookingApiService(dioClient);
});

// Repositories
final tripRepositoryProvider = Provider<ITripRepository>((ref) {
  final apiService = ref.watch(tripApiServiceProvider);
  return TripRepositoryImpl(apiService);
});

final bookingRepositoryProvider = Provider<IBookingRepository>((ref) {
  final apiService = ref.watch(bookingApiServiceProvider);
  return BookingRepositoryImpl(apiService);
});

// Query providers
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

final getUpcomingTripsForDriverProvider = FutureProvider.family<List, String>(
  (ref, driverId) async {
    final repository = ref.watch(tripRepositoryProvider);
    return repository.getUpcomingTripsForDriver(driverId);
  },
);

final getUpcomingBookingsForPassengerProvider =
    FutureProvider.family<List, String>(
  (ref, passengerId) async {
    final repository = ref.watch(bookingRepositoryProvider);
    return repository.getUpcomingBookingsForPassenger(passengerId);
  },
);

// workaround: newly created bookings don't appear in list immediately from backend
final localBookingsCacheProvider = StateNotifierProvider.family<
    LocalBookingsCacheNotifier,
    List<PassengerRideResponse>,
    String>((ref, passengerId) {
  return LocalBookingsCacheNotifier();
});

class LocalBookingsCacheNotifier extends StateNotifier<List<PassengerRideResponse>> {
  LocalBookingsCacheNotifier() : super([]);

  void addBooking(PassengerRideResponse booking) {
    state = [...state, booking];
  }

  void removeBooking({String? rideId, String? tripId}) {
    state = state.where((booking) {
      final rideMatch = rideId != null && booking.rideId == rideId;
      final tripMatch = tripId != null && booking.tripId == tripId;
      return !(rideMatch || tripMatch);
    }).toList();
  }

  void clearCache() {
    state = [];
  }
}
