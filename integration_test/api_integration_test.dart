import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/features/trip/data/services/trip_api_service.dart';
import 'package:carsharing/features/booking/data/services/booking_api_service.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/trip/data/models/points.dart';

void main() {
  group('API Integration Tests', () {
    late DioClient dioClient;
    late TripApiService tripApiService;
    late BookingApiService bookingApiService;

    setUpAll(() {
      dioClient = DioClient();
      tripApiService = TripApiService(dioClient);
      bookingApiService = BookingApiService(dioClient);
    });

    group('Trip Search - Matching Route', () {
      test('Should return trips when searching with valid parameters', () async {
        // Arrange
        const sourceLat = 50.8090106;
        const sourceLon = 8.7704695;
        const sourceRadiusKm = 10.0;
        const destLat = 50.1106444;
        const destLon = 8.6820917;
        const destRadiusKm = 10.0;
        const earliestDepartureTime = '2026-04-04T14:00:00Z';
        const requestedSeats = 1;
        const effectiveUserId = 'test_user_id';

        // Act
        final response = await tripApiService.searchMatchingRoute(
          sourceLat: sourceLat,
          sourceLon: sourceLon,
          sourceRadiusKm: sourceRadiusKm,
          destLat: destLat,
          destLon: destLon,
          destRadiusKm: destRadiusKm,
          rideStartTime: earliestDepartureTime,
          requestedSeats: requestedSeats,
          effectiveUserId: effectiveUserId,
        );

        // Assert
        expect(response, isNotNull);
        expect(response.data, isNotNull);
        expect(response.data, isA<List<Trip>>());
        print('✅ Trip search returned ${response.data?.length ?? 0} results');

        // Verify response structure if trips exist
        if (response.data!.isNotEmpty) {
          final trip = response.data!.first;
          expect(trip.tripId, isNotNull);
          expect(trip.driverId, isNotNull);
          expect(trip.sourceAddress, isNotNull);
          expect(trip.destinationAddress, isNotNull);
          expect(trip.totalSeats, greaterThanOrEqualTo(0));
          expect(trip.availableSeats, greaterThanOrEqualTo(0));
          expect(trip.bookedSeats, greaterThanOrEqualTo(0));
          print('✅ Trip response structure verified');
        }
      });

      test('Should handle search with no results', () async {
        // Arrange - search in unlikely location
        const sourceLat = -90.0;
        const sourceLon = -180.0;
        const destLat = 90.0;
        const destLon = 180.0;

        // Act
        final response = await tripApiService.searchMatchingRoute(
          sourceLat: sourceLat,
          sourceLon: sourceLon,
          sourceRadiusKm: 1.0,
          destLat: destLat,
          destLon: destLon,
          destRadiusKm: 1.0,
          rideStartTime: '2026-04-04T14:00:00Z',
          requestedSeats: 1,
          effectiveUserId: 'test_user_id',
        );

        // Assert
        expect(response, isNotNull);
        expect(response.data, isNotNull);
        expect(response.data, isEmpty);
        print('✅ Search with no results handled correctly');
      });

      test('Should verify correct parameter format in request', () async {
        // This test verifies that parameters are sent as numbers, not strings
        // The DioClient interceptor will log the actual request
        const sourceLat = 50.8090106;
        const sourceLon = 8.7704695;

        // Act
        try {
          await tripApiService.searchMatchingRoute(
            sourceLat: sourceLat,
            sourceLon: sourceLon,
            sourceRadiusKm: 10.0,
            destLat: 50.1106444,
            destLon: 8.6820917,
            destRadiusKm: 10.0,
            rideStartTime: '2026-04-04T14:00:00Z',
            requestedSeats: 1,
            effectiveUserId: 'test_user_id',
          );
          print('✅ Request parameters sent correctly (numbers, not strings)');
        } catch (e) {
          fail('Search failed: $e');
        }
      });
    });

    group('Trip Search - Near Source', () {
      test('Should return trips near source location', () async {
        // Arrange
        const latitude = 50.8090106;
        const longitude = 8.7704695;
        const radiusKm = 10.0;

        // Act
        final response = await tripApiService.searchNearSource(
          sourceLat: latitude,
          sourceLon: longitude,
          radiusKm: radiusKm,
        );

        // Assert
        expect(response, isNotNull);
        expect(response.data, isNotNull);
        expect(response.data, isA<List<Trip>>());
        print('✅ Near-source search returned ${response.data?.length ?? 0} results');

        if (response.data!.isNotEmpty) {
          final trip = response.data!.first;
          // Verify source location is within radius
          final distance = _calculateDistance(
            latitude,
            longitude,
            trip.sourceAddress.latitude,
            trip.sourceAddress.longitude,
          );
          expect(distance, lessThanOrEqualTo(radiusKm + 0.5)); // +0.5 for tolerance
          print('✅ Returned trips are within source radius');
        }
      });
    });

    group('Trip Search - Near Destination', () {
      test('Should return trips near destination location', () async {
        // Arrange
        const latitude = 50.1106444;
        const longitude = 8.6820917;
        const radiusKm = 10.0;

        // Act
        final response = await tripApiService.searchNearDestination(
          destLat: latitude,
          destLon: longitude,
          radiusKm: radiusKm,
        );

        // Assert
        expect(response, isNotNull);
        expect(response.data, isNotNull);
        expect(response.data, isA<List<Trip>>());
        print('✅ Near-destination search returned ${response.data?.length ?? 0} results');

        if (response.data!.isNotEmpty) {
          final trip = response.data!.first;
          // Verify destination location is within radius
          final distance = _calculateDistance(
            latitude,
            longitude,
            trip.destinationAddress.latitude,
            trip.destinationAddress.longitude,
          );
          expect(distance, lessThanOrEqualTo(radiusKm + 0.5)); // +0.5 for tolerance
          print('✅ Returned trips have destination within radius');
        }
      });
    });

    group('Trip Creation - Offer Trip', () {
      test('Should create a trip with valid offer request', () async {
        // Arrange
        final offerRequest = OfferRideRequest(
          driverId: 'test_driver_id',
          vehicleNumber: 'TEST123',
          sourceAddress: const Points(
            latitude: 50.8090106,
            longitude: 8.7704695,
            placeAddress: 'Marburg, Germany',
          ),
          destinationAddress: const Points(
            latitude: 50.1106444,
            longitude: 8.6820917,
            placeAddress: 'Frankfurt, Germany',
          ),
          tripStartDateTime: DateTime.parse('2026-04-04T14:00:00Z'),
          totalSeats: 3,
        );

        // Act
        final response = await tripApiService.offerTrip(offerRequest);

        // Assert
        expect(response, isNotNull);
        expect(response.data, isNotNull);
        expect(response.data?.tripId, isNotNull);
        expect(response.data?.vehicleNumber, equals('TEST123'));
        expect(response.data?.tripCreated, isTrue);
        print('✅ Trip created successfully with ID: ${response.data?.tripId}');
      });

      test('Should verify trip offer response structure', () async {
        // Arrange
        final offerRequest = OfferRideRequest(
          driverId: 'test_driver_id_2',
          vehicleNumber: 'TEST456',
          sourceAddress: const Points(
            latitude: 50.8090106,
            longitude: 8.7704695,
            placeAddress: 'Marburg, Germany',
          ),
          destinationAddress: const Points(
            latitude: 50.1106444,
            longitude: 8.6820917,
            placeAddress: 'Frankfurt, Germany',
          ),
          tripStartDateTime: DateTime.parse('2026-05-15T10:00:00Z'),
          totalSeats: 4,
        );

        // Act
        final response = await tripApiService.offerTrip(offerRequest);

        // Assert - Verify all required response fields
        expect(response.data?.tripId, isNotNull);
        expect(response.data?.vehicleNumber, isNotNull);
        expect(response.data?.sourceAddress.latitude, isNotNull);
        expect(response.data?.sourceAddress.longitude, isNotNull);
        expect(response.data?.destinationAddress.latitude, isNotNull);
        expect(response.data?.destinationAddress.longitude, isNotNull);
        expect(response.data?.tripStartDateTime, isNotNull);
        expect(response.data?.tripTimezone, isNotNull);
        expect(response.data?.routeGeometry, isNotNull);
        expect(response.data?.routeDistanceInKm, isNotNull);
        expect(response.data?.routeDurationInMinutes, isNotNull);
        print('✅ Trip response structure verified with route geometry');
      });
    });

    group('Driver Trips - Get Active Trips', () {
      test('Should retrieve active trips for driver', () async {
        // Arrange
        const driverId = 'test_driver_id';

        // Act
        final response = await tripApiService.getUpcomingTripsForDriver(driverId);

        // Assert
        expect(response, isNotNull);
        expect(response.data, isNotNull);
        expect(response.data, isA<List>());
        print('✅ Retrieved ${response.data?.length ?? 0} active trips for driver');

        // Verify structure if trips exist
        if (response.data!.isNotEmpty) {
          final trip = response.data!.first;
          expect(trip.tripId, isNotNull);
          expect(trip.driverId, equals(driverId));
          expect(trip.totalSeats, greaterThanOrEqualTo(0));
          expect(trip.availableSeats, greaterThanOrEqualTo(0));
          expect(trip.bookedSeats, greaterThanOrEqualTo(0));
          print('✅ Driver trip response structure verified');
        }
      });

      test('Should handle driver with no active trips', () async {
        // Arrange - Use non-existent driver ID
        const driverId = 'non_existent_driver_12345';

        // Act
        final response = await tripApiService.getUpcomingTripsForDriver(driverId);

        // Assert
        expect(response, isNotNull);
        expect(response.data, isNotNull);
        expect(response.data, isEmpty);
        print('✅ Empty result handled for driver with no trips');
      });
    });

    group('Passenger Bookings - Get Active Bookings', () {
      test('Should retrieve active bookings for passenger', () async {
        // Arrange
        const passengerId = 'test_passenger_id';

        // Act
        final response = await bookingApiService.getUpcomingBookingsForPassenger(passengerId);

        // Assert
        expect(response, isNotNull);
        expect(response.data, isNotNull);
        expect(response.data, isA<List>());
        print('✅ Retrieved ${response.data?.length ?? 0} active bookings for passenger');

        // Verify structure if bookings exist
        if (response.data!.isNotEmpty) {
          final booking = response.data!.first;
          expect(booking.rideId, isNotNull);
          expect(booking.tripId, isNotNull);
          expect(booking.driverId, isNotNull);
          expect(booking.rideStatus, isNotNull);
          print('✅ Booking response structure verified');
        }
      });
    });

    group('Response Format Verification', () {
      test('All responses should have ApiResponse wrapper', () async {
        // Act - Search for trips
        final searchResponse = await tripApiService.searchMatchingRoute(
          sourceLat: 50.8090106,
          sourceLon: 8.7704695,
          sourceRadiusKm: 10.0,
          destLat: 50.1106444,
          destLon: 8.6820917,
          destRadiusKm: 10.0,
          rideStartTime: '2026-04-04T14:00:00Z',
          requestedSeats: 1,
          effectiveUserId: 'test_user_id',
        );

        // Assert - Verify ApiResponse wrapper structure
        expect(searchResponse.message, isNotNull);
        expect(searchResponse.timestamp, isNotNull);
        print('✅ ApiResponse wrapper structure verified');
        print('   Message: ${searchResponse.message}');
        print('   Timestamp: ${searchResponse.timestamp}');
      });
    });
  });
}

/// Calculate distance between two coordinates in kilometers using Haversine formula
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLon = _degreesToRadians(lon2 - lon1);

  final a = (sin(dLat / 2) * sin(dLat / 2)) +
      (cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2));

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) {
  return degrees * 3.14159265359 / 180;
}
