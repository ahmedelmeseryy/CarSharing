import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_response.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';

// Handles creating a new trip offer (driver)
class OfferTripNotifier extends StateNotifier<AsyncValue<OfferRideResponse?>> {
  final Ref _ref;

  OfferTripNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> offerTrip(OfferRideRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(tripRepositoryProvider).offerTrip(request),
    );
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final offerTripProvider = StateNotifierProvider.autoDispose<
    OfferTripNotifier,
    AsyncValue<OfferRideResponse?>>((ref) {
  return OfferTripNotifier(ref);
});

// Handles a passenger joining an existing trip
class JoinTripNotifier
    extends StateNotifier<AsyncValue<PassengerRideResponse?>> {
  final Ref _ref;

  JoinTripNotifier(this._ref) : super(const AsyncValue.data(null));

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

final joinTripProvider = StateNotifierProvider<
    JoinTripNotifier,
    AsyncValue<PassengerRideResponse?>>((ref) {
  return JoinTripNotifier(ref);
});

// Handles a driver cancelling their trip
class CancelTripNotifier extends StateNotifier<AsyncValue<String>> {
  final Ref _ref;

  CancelTripNotifier(this._ref) : super(const AsyncValue.data(''));

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

final cancelTripProvider = StateNotifierProvider.autoDispose<
    CancelTripNotifier,
    AsyncValue<String>>((ref) {
  return CancelTripNotifier(ref);
});

// Handles a passenger cancelling their booking
class CancelBookingNotifier extends StateNotifier<AsyncValue<String>> {
  final Ref _ref;

  CancelBookingNotifier(this._ref) : super(const AsyncValue.data(''));

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

final cancelBookingProvider = StateNotifierProvider.autoDispose<
    CancelBookingNotifier,
    AsyncValue<String>>((ref) {
  return CancelBookingNotifier(ref);
});
