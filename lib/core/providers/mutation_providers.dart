import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_response.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';

/// State notifier for offering a trip
/// Use this to create new trip offers with loading/error handling
class OfferTripNotifier extends StateNotifier<AsyncValue<OfferRideResponse?>> {
  final Ref _ref;

  OfferTripNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Create a new trip offer
  /// - Shows loading state immediately
  /// - Handles errors gracefully
  /// - Returns the created trip response
  Future<void> offerTrip(OfferRideRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(tripRepositoryProvider).offerTrip(request),
    );
  }

  /// Reset state to idle
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for offering a trip
/// Usage:
/// ```dart
/// final notifier = ref.read(offerTripProvider.notifier);
/// await notifier.offerTrip(offerRideRequest);
/// final response = ref.watch(offerTripProvider);
/// ```
final offerTripProvider = StateNotifierProvider.autoDispose<
    OfferTripNotifier,
    AsyncValue<OfferRideResponse?>>((ref) {
  return OfferTripNotifier(ref);
});

/// State notifier for joining a trip
class JoinTripNotifier
    extends StateNotifier<AsyncValue<PassengerRideResponse?>> {
  final Ref _ref;

  JoinTripNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Join an existing trip as a passenger
  /// - Shows loading state immediately
  /// - Handles errors (trip full, invalid, already joined, etc.)
  /// - Returns the booking confirmation
  Future<void> joinTrip(JoinTripRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(bookingRepositoryProvider).joinTrip(request),
    );
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for joining a trip
/// Usage:
/// ```dart
/// final notifier = ref.read(joinTripProvider.notifier);
/// await notifier.joinTrip(joinTripRequest);
/// final booking = ref.watch(joinTripProvider);
/// ```
final joinTripProvider = StateNotifierProvider.autoDispose<
    JoinTripNotifier,
    AsyncValue<PassengerRideResponse?>>((ref) {
  return JoinTripNotifier(ref);
});

/// State notifier for cancelling a trip (driver)
class CancelTripNotifier extends StateNotifier<AsyncValue<String>> {
  final Ref _ref;

  CancelTripNotifier(this._ref) : super(const AsyncValue.data(''));

  /// Cancel a trip offering (driver only)
  /// - Shows loading state immediately
  /// - Handles errors (trip not found, already in progress, etc.)
  /// - Returns success/status message
  Future<void> cancelTrip(CancelTripRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(tripRepositoryProvider).cancelTrip(request),
    );
  }

  void reset() {
    state = const AsyncValue.data('');
  }
}

/// Provider for cancelling a trip (driver)
/// Usage:
/// ```dart
/// final notifier = ref.read(cancelTripProvider.notifier);
/// await notifier.cancelTrip(cancelTripRequest);
/// final status = ref.watch(cancelTripProvider);
/// ```
final cancelTripProvider = StateNotifierProvider.autoDispose<
    CancelTripNotifier,
    AsyncValue<String>>((ref) {
  return CancelTripNotifier(ref);
});

/// State notifier for cancelling a booking (passenger)
class CancelBookingNotifier extends StateNotifier<AsyncValue<String>> {
  final Ref _ref;

  CancelBookingNotifier(this._ref) : super(const AsyncValue.data(''));

  /// Cancel a booking (passenger only)
  /// - Shows loading state immediately
  /// - Handles errors (booking not found, already completed, too late, etc.)
  /// - Returns success/status message
  Future<void> cancelBooking(CancelTripRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(bookingRepositoryProvider).cancelBooking(request),
    );
  }

  void reset() {
    state = const AsyncValue.data('');
  }
}

/// Provider for cancelling a booking (passenger)
/// Usage:
/// ```dart
/// final notifier = ref.read(cancelBookingProvider.notifier);
/// await notifier.cancelBooking(cancelTripRequest);
/// final status = ref.watch(cancelBookingProvider);
/// ```
final cancelBookingProvider = StateNotifierProvider.autoDispose<
    CancelBookingNotifier,
    AsyncValue<String>>((ref) {
  return CancelBookingNotifier(ref);
});
