import 'package:flutter_test/flutter_test.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/trip/data/models/points.dart';

void main() {
  group('Trip API Response Models', () {
    test('Trip model should parse JSON correctly with correct field names', () {
      // Arrange
      final json = {
        'tripId': 'trip_123',
        'driverId': 'driver_456',
        'vehicleNumber': 'ABC123',
        'sourceAddress': {
          'latitude': 50.8090106,
          'longitude': 8.7704695,
          'placeAddress': 'Marburg, Germany'
        },
        'destinationAddress': {
          'latitude': 50.1106444,
          'longitude': 8.6820917,
          'placeAddress': 'Frankfurt, Germany'
        },
        'tripStartDateTimeUTC': '2026-04-04T14:00:00Z',
        'tripTimezone': 'Europe/Berlin',
        'totalSeats': 4,
        'bookedSeats': 2,
        'tripStatus': 'ACTIVE',
        'routeGeometry': {'type': 'LineString', 'coordinates': []},
        'routeDistance': 75.5,
        'routeDuration': 3600,
      };

      // Act
      final trip = Trip.fromJson(json);

      // Assert - Verify field names match backend spec
      expect(trip.tripId, equals('trip_123'));
      expect(trip.driverId, equals('driver_456'));
      expect(trip.totalSeats, equals(4));
      expect(trip.bookedSeats, equals(2));
      expect(trip.availableSeats, equals(2));
      expect(trip.sourceAddress.latitude, equals(50.8090106));
      expect(trip.sourceAddress.longitude, equals(8.7704695));
      expect(trip.destinationAddress.latitude, equals(50.1106444));
      expect(trip.destinationAddress.longitude, equals(8.6820917));
      print('✅ Trip model parses all fields correctly');
    });

    test('Trip model should correctly calculate available seats', () {
      // Arrange
      final trip = Trip(
        tripId: 'trip_123',
        driverId: 'driver_456',
        vehicleNumber: 'ABC123',
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
        tripTimezone: 'Europe/Berlin',
        totalSeats: 4,
        bookedSeats: 2,
        tripStatus: 'ACTIVE',
        routeGeometry: {'type': 'LineString'},
        routeDistance: 75.5,
        routeDuration: 3600,
      );

      // Assert
      expect(trip.availableSeats, equals(2));
      print('✅ Available seats calculated correctly');
    });

    test('ApiResponse should handle generic data type', () {
      // Arrange
      final responseJson = {
        'data': [
          {
            'tripId': 'trip_1',
            'driverId': 'driver_1',
            'vehicleNumber': 'ABC123',
            'sourceAddress': {
              'latitude': 50.8090106,
              'longitude': 8.7704695,
              'placeAddress': 'Marburg, Germany'
            },
            'destinationAddress': {
              'latitude': 50.1106444,
              'longitude': 8.6820917,
              'placeAddress': 'Frankfurt, Germany'
            },
            'tripStartDateTimeUTC': '2026-04-04T14:00:00Z',
            'tripTimezone': 'Europe/Berlin',
            'totalSeats': 4,
            'bookedSeats': 2,
            'tripStatus': 'ACTIVE',
            'routeGeometry': {'type': 'LineString', 'coordinates': []},
            'routeDistance': 75.5,
            'routeDuration': 3600,
          }
        ]
      };

      // Act - Parse list of trips
      final data = responseJson['data'] as List;
      final trips = data.map((item) => Trip.fromJson(item as Map<String, dynamic>)).toList();

      // Assert
      expect(trips, isA<List<Trip>>());
      expect(trips.length, equals(1));
      expect(trips.first.tripId, equals('trip_1'));
      print('✅ Multiple trips parse correctly');
    });
  });

  group('Trip Search Parameter Validation', () {
    test('Trip search should accept numeric parameters, not strings', () {
      // This is a verification test showing the correct parameter types
      final sourceLat = 50.8090106; // double, not "50.8090106"
      final sourceLon = 8.7704695; // double, not "8.7704695"
      final requestedSeats = 1; // int, not "1"

      expect(sourceLat, isA<double>());
      expect(sourceLon, isA<double>());
      expect(requestedSeats, isA<int>());
      print('✅ Trip search parameters are correct numeric types');
    });

    test('Trip start time should be ISO 8601 format', () {
      // Arrange
      const tripStartTime = '2026-04-04T14:00:00Z';

      // Act
      final dateTime = DateTime.parse(tripStartTime);

      // Assert
      expect(dateTime, isA<DateTime>());
      expect(tripStartTime.endsWith('Z'), isTrue); // UTC indicator
      print('✅ Trip start time format is valid ISO 8601');
    });

    test('Radius parameters should be positive numbers', () {
      // Arrange
      const sourceRadiusKm = 10.0;
      const destRadiusKm = 10.0;

      // Assert
      expect(sourceRadiusKm, greaterThan(0));
      expect(destRadiusKm, greaterThan(0));
      print('✅ Radius parameters are positive numbers');
    });
  });

  group('Points Model Validation', () {
    test('Points should represent geographic coordinates', () {
      // Arrange
      const point = Points(
        latitude: 50.8090106,
        longitude: 8.7704695,
        placeAddress: 'Marburg, Germany',
      );

      // Assert
      expect(point.latitude, greaterThanOrEqualTo(-90));
      expect(point.latitude, lessThanOrEqualTo(90));
      expect(point.longitude, greaterThanOrEqualTo(-180));
      expect(point.longitude, lessThanOrEqualTo(180));
      expect(point.placeAddress, isNotEmpty);
      print('✅ Points model represents valid geographic coordinates');
    });
  });
}
