import 'package:flutter_test/flutter_test.dart';
import 'package:carsharing/services/trip_search_service.dart';

void main() {
  group('TripSearchService - Haversine Distance Calculation', () {
    test('calculates distance between two identical points as zero', () {
      const lat = 50.813;
      const lon = 8.681;
      final distance = TripSearchService.calculateDistance(lat, lon, lat, lon);
      expect(distance, closeTo(0.0, 0.001));
    });

    test('calculates distance between Marburg and Berlin', () {
      // Marburg: 50.813, 8.681
      // Berlin: 52.52, 13.405
      // Approximate distance: ~377 km
      final distance = TripSearchService.calculateDistance(
        50.813,
        8.681,
        52.52,
        13.405,
      );
      expect(distance, greaterThan(350));
      expect(distance, lessThan(400));
    });

    test('calculates distance between two points ~100km apart', () {
      // Frankfurt: 50.1109, 8.6821
      // Mannheim: 49.4891, 8.4673
      // Approximate distance: ~60 km
      final distance = TripSearchService.calculateDistance(
        50.1109,
        8.4821,
        49.4891,
        8.4673,
      );
      expect(distance, greaterThan(50));
      expect(distance, lessThan(90));
    });

    test('distance is symmetric (A to B equals B to A)', () {
      final distanceAB = TripSearchService.calculateDistance(
        50.813,
        8.681,
        52.52,
        13.405,
      );
      final distanceBA = TripSearchService.calculateDistance(
        52.52,
        13.405,
        50.813,
        8.681,
      );
      expect(distanceAB, closeTo(distanceBA, 0.01));
    });
  });

  group('TripSearchService - Distance Formatting', () {
    test('formats distance less than 1km in meters', () {
      final formatted = TripSearchService.formatDistance(0.5);
      expect(formatted, equals('500 m'));
    });

    test('formats distance more than 1km in kilometers', () {
      final formatted = TripSearchService.formatDistance(2.5);
      expect(formatted, equals('2.5 km'));
    });

    test('formats very small distance', () {
      final formatted = TripSearchService.formatDistance(0.1);
      expect(formatted, equals('100 m'));
    });

    test('formats large distance', () {
      final formatted = TripSearchService.formatDistance(150.0);
      expect(formatted, equals('150.0 km'));
    });
  });

  group('TripSearchService - Filter and Rank by Distance', () {
    late List<dynamic> mockTrips;

    setUp(() {
      mockTrips = [
        {
          'id': 'trip-1',
          'start': 'Marburg Center',
          'end': 'Frankfurt',
          'pickupLocation': {
            'latitude': 50.815,
            'longitude': 8.680,
          },
          'seats': 3,
          'price': 15,
        },
        {
          'id': 'trip-2',
          'start': 'Marburg South',
          'end': 'Berlin',
          'pickupLocation': {
            'latitude': 50.810,
            'longitude': 8.670,
          },
          'seats': 2,
          'price': 20,
        },
        {
          'id': 'trip-3',
          'start': 'Marburg North',
          'end': 'Munich',
          'pickupLocation': {
            'latitude': 50.820,
            'longitude': 8.690,
          },
          'seats': 4,
          'price': 25,
        },
        {
          'id': 'trip-4',
          'start': 'Frankfurt',
          'end': 'Stuttgart',
          'pickupLocation': {
            'latitude': 50.1109,
            'longitude': 8.6821,
          },
          'seats': 2,
          'price': 18,
        },
      ];
    });

    test('returns trips within specified radius', () {
      // User location: Marburg (50.813, 8.681)
      // Search radius: 5 km
      // Expected: trips 1, 2, 3 (all near Marburg, < 5km from user)
      final results = TripSearchService.filterAndRankByDistance(
        mockTrips,
        50.813,
        8.681,
        radiusKm: 5.0,
      );

      expect(results.length, equals(3));
      expect(results.map((r) => r.trip['id']).toList(),
          containsAll(['trip-1', 'trip-2', 'trip-3']));
    });

    test('excludes trips outside the specified radius', () {
      // User location: Marburg (50.813, 8.681)
      // Search radius: 5 km
      // Frankfurt (trip-4) is ~60km away, should be excluded
      final results = TripSearchService.filterAndRankByDistance(
        mockTrips,
        50.813,
        8.681,
        radiusKm: 5.0,
      );

      expect(results.map((r) => r.trip['id']).toList(),
          isNot(contains('trip-4')));
    });

    test('ranks trips by distance (nearest first)', () {
      final results = TripSearchService.filterAndRankByDistance(
        mockTrips,
        50.813,
        8.681,
        radiusKm: 5.0,
      );

      // All results should be sorted by distance
      for (int i = 0; i < results.length - 1; i++) {
        expect(
          results[i].distanceKm,
          lessThanOrEqualTo(results[i + 1].distanceKm),
        );
      }
    });

    test('handles trips with no pickupLocation gracefully', () {
      final tripsWithMissing = [
        {
          'id': 'trip-no-location',
          'start': 'Somewhere',
          'end': 'Elsewhere',
          // No pickupLocation
        },
        {
          'id': 'trip-with-location',
          'start': 'Marburg',
          'end': 'Frankfurt',
          'pickupLocation': {
            'latitude': 50.815,
            'longitude': 8.680,
          },
        },
      ];

      final results = TripSearchService.filterAndRankByDistance(
        tripsWithMissing,
        50.813,
        8.681,
        radiusKm: 5.0,
      );

      // Only the trip with valid location should be returned
      expect(results.length, equals(1));
      expect(results[0].trip['id'], equals('trip-with-location'));
    });

    test('returns empty list when no trips are within radius', () {
      final results = TripSearchService.filterAndRankByDistance(
        mockTrips,
        40.0, // Very different latitude (southern Europe)
        10.0, // Very different longitude
        radiusKm: 5.0,
      );

      expect(results.isEmpty, true);
    });

    test('uses larger radius to include more trips', () {
      // Small radius
      final smallRadiusResults = TripSearchService.filterAndRankByDistance(
        mockTrips,
        50.813,
        8.681,
        radiusKm: 5.0,
      );

      // Large radius
      final largeRadiusResults = TripSearchService.filterAndRankByDistance(
        mockTrips,
        50.813,
        8.681,
        radiusKm: 100.0,
      );

      expect(largeRadiusResults.length, greaterThan(smallRadiusResults.length));
    });

    test('TripWithDistance stores correct distance values', () {
      final results = TripSearchService.filterAndRankByDistance(
        mockTrips,
        50.813,
        8.681,
        radiusKm: 5.0,
      );

      // All stored distances should be >= 0
      for (final tripWithDistance in results) {
        expect(tripWithDistance.distanceKm, greaterThanOrEqualTo(0));
        expect(tripWithDistance.distanceKm, lessThanOrEqualTo(5.0));
      }
    });

    test('multiple trips at same location have zero distance between them', () {
      final results = TripSearchService.filterAndRankByDistance(
        [
          {
            'id': 'trip-a',
            'pickupLocation': {'latitude': 50.813, 'longitude': 8.681},
          },
          {
            'id': 'trip-b',
            'pickupLocation': {'latitude': 50.813, 'longitude': 8.681},
          },
        ],
        50.813,
        8.681,
        radiusKm: 1.0,
      );

      expect(results.length, equals(2));
      expect(results[0].distanceKm, closeTo(0.0, 0.001));
      expect(results[1].distanceKm, closeTo(0.0, 0.001));
    });
  });

  group('TripSearchService - Integration Tests', () {
    test('realistic scenario: search around a city', () {
      // Simulate a user in Frankfurt searching for trips
      final frankfurtTrips = [
        {
          'id': 'frankfurt-trip-1',
          'start': 'Frankfurt Central',
          'end': 'Mannheim',
          'pickupLocation': {
            'latitude': 50.1109,
            'longitude': 8.6821,
          },
          'seats': 2,
          'price': 12,
        },
        {
          'id': 'frankfurt-trip-2',
          'start': 'Frankfurt Airport',
          'end': 'Heidelberg',
          'pickupLocation': {
            'latitude': 50.0365,
            'longitude': 8.5623,
          },
          'seats': 3,
          'price': 14,
        },
        {
          'id': 'marburg-trip',
          'start': 'Marburg',
          'end': 'Berlin',
          'pickupLocation': {
            'latitude': 50.813,
            'longitude': 8.681,
          },
          'seats': 4,
          'price': 45,
        },
      ];

      final results = TripSearchService.filterAndRankByDistance(
        frankfurtTrips,
        50.1109, // Frankfurt
        8.6821,
        radiusKm: 30.0,
      );

      // Should include Frankfurt trips, but Marburg is ~60km away
      expect(results.length, equals(2));
      expect(results.map((r) => r.trip['id']).toList(),
          containsAll(['frankfurt-trip-1', 'frankfurt-trip-2']));
    });
  });
}
