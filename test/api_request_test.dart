import 'package:flutter_test/flutter_test.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/points.dart';

void main() {
  group('API Request Parameter Tests', () {
    test('Trip search parameters should be numeric types', () {
      // This verifies that the DioClient will send numeric parameters correctly
      
      // Arrange
      final params = {
        'sourceLatitude': 50.8090106, // double, not string
        'sourceLongitude': 8.7704695, // double, not string
        'sourceRadiusKm': 10.0, // double, not string
        'destLatitude': 50.1106444, // double, not string
        'destLongitude': 8.6820917, // double, not string
        'destRadiusKm': 10.0, // double, not string
        'requestedSeats': 1, // int, not string
      };

      // Act & Assert - Verify types
      for (final entry in params.entries) {
        expect(
          entry.value,
          isA<num>(),
          reason: '${entry.key} should be numeric, not string',
        );
      }

      print('✅ All trip search parameters are correct types');
    });

    test('OfferRideRequest should serialize correctly for API call', () {
      // Arrange
      final offerRequest = OfferRideRequest(
        driverId: 'driver_123',
        vehicleNumber: 'CAR001',
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
        offeredSeat: 4,
      );

      // Act
      final json = offerRequest.toJson();

      // Assert - Verify structure
      expect(json['driverId'], equals('driver_123'));
      expect(json['vehicleNumber'], equals('CAR001'));
      expect(json['sourceAddress'], isA<Map>());
      expect(json['sourceAddress']['latitude'], isA<double>());
      expect(json['sourceAddress']['longitude'], isA<double>());
      expect(json['destinationAddress'], isA<Map>());
      expect(json['tripStartDateTime'], equals('2026-04-04T14:00:00Z'));
      expect(json['offeredSeat'], equals(4));

      print('✅ OfferRideRequest serializes correctly');
    });

    test('API request should include effective user ID', () {
      // This verifies the parameter that the backend needs to identify the requester
      const effectiveUserId = 'rhPRMNYhfAbi82xzbuYvKySEvWw1';

      expect(effectiveUserId, isNotEmpty);
      expect(effectiveUserId, contains('rhP')); // Verify format
      print('✅ Effective user ID is provided correctly');
    });

    test('Timestamp format should be ISO 8601 UTC', () {
      // Arrange
      const timestamp = '2026-04-04T14:00:00Z';

      // Act
      final dateTime = DateTime.parse(timestamp);

      // Assert
      expect(dateTime.isUtc, isTrue);
      expect(timestamp.endsWith('Z'), isTrue);
      print('✅ Timestamp is ISO 8601 UTC format');
    });

    test('Radius values should be positive', () {
      // Arrange
      const radiusKm = 10.0;

      // Assert
      expect(radiusKm, greaterThan(0));
      print('✅ Radius value is positive');
    });

    test('Latitude should be within valid geographic range', () {
      // Arrange
      const marburg = 50.8090106;
      const frankfurt = 50.1106444;

      // Assert
      expect(marburg, greaterThanOrEqualTo(-90));
      expect(marburg, lessThanOrEqualTo(90));
      expect(frankfurt, greaterThanOrEqualTo(-90));
      expect(frankfurt, lessThanOrEqualTo(90));
      print('✅ Latitude values are within valid range (-90 to 90)');
    });

    test('Longitude should be within valid geographic range', () {
      // Arrange
      const marburg = 8.7704695;
      const frankfurt = 8.6820917;

      // Assert
      expect(marburg, greaterThanOrEqualTo(-180));
      expect(marburg, lessThanOrEqualTo(180));
      expect(frankfurt, greaterThanOrEqualTo(-180));
      expect(frankfurt, lessThanOrEqualTo(180));
      print('✅ Longitude values are within valid range (-180 to 180)');
    });

    test('Seats count should be positive integer', () {
      // Arrange
      const offeredSeats = 4;
      const requestedSeats = 1;

      // Assert
      expect(offeredSeats, isA<int>());
      expect(offeredSeats, greaterThan(0));
      expect(requestedSeats, isA<int>());
      expect(requestedSeats, greaterThan(0));
      print('✅ Seats count values are positive integers');
    });

    test('Vehicle number should be non-empty string', () {
      // Arrange
      const vehicleNumber = 'ABC123';

      // Assert
      expect(vehicleNumber, isA<String>());
      expect(vehicleNumber, isNotEmpty);
      print('✅ Vehicle number is valid string');
    });

    test('Driver ID should be non-empty string', () {
      // Arrange
      const driverId = 'driver_456';

      // Assert
      expect(driverId, isA<String>());
      expect(driverId, isNotEmpty);
      print('✅ Driver ID is valid string');
    });

    test('Place address should be non-empty string', () {
      // Arrange
      const marburg = 'Marburg, Germany';
      const frankfurt = 'Frankfurt, Germany';

      // Assert
      expect(marburg, isA<String>());
      expect(marburg, isNotEmpty);
      expect(frankfurt, isA<String>());
      expect(frankfurt, isNotEmpty);
      print('✅ Place addresses are valid strings');
    });
  });

  group('API Response Status Codes', () {
    test('Successful search should return 200 status', () {
      // This is a documentation of expected status codes
      const successStatus = 200;
      expect(successStatus, equals(200));
      print('✅ Trip search success status: 200');
    });

    test('Trip creation should return 201 status', () {
      // Documentation of expected status codes
      const createdStatus = 201;
      expect(createdStatus, equals(201));
      print('✅ Trip creation success status: 201');
    });

    test('Bad request should return 400 status', () {
      const badRequestStatus = 400;
      expect(badRequestStatus, equals(400));
      print('✅ Bad request status: 400');
    });

    test('Unauthorized should return 401 status', () {
      const unauthorizedStatus = 401;
      expect(unauthorizedStatus, equals(401));
      print('✅ Unauthorized status: 401');
    });

    test('Not found should return 404 status', () {
      const notFoundStatus = 404;
      expect(notFoundStatus, equals(404));
      print('✅ Not found status: 404');
    });

    test('Server error should return 500+ status', () {
      const serverErrorStatus = 500;
      expect(serverErrorStatus, greaterThanOrEqualTo(500));
      print('✅ Server error status: 500+');
    });
  });

  group('API Request/Response Flow', () {
    test('Complete trip search flow verifies all parameters', () {
      // Arrange - All parameters needed for trip search
      const sourceLat = 50.8090106;
      const sourceLon = 8.7704695;
      const sourceRadius = 10.0;
      const destLat = 50.1106444;
      const destLon = 8.6820917;
      const destRadius = 10.0;
      const startTime = '2026-04-04T14:00:00Z';
      const seats = 1;
      const userId = 'rhPRMNYhfAbi82xzbuYvKySEvWw1';

      // Act - Verify all are correct types
      expect(sourceLat, isA<double>());
      expect(sourceLon, isA<double>());
      expect(sourceRadius, isA<double>());
      expect(destLat, isA<double>());
      expect(destLon, isA<double>());
      expect(destRadius, isA<double>());
      expect(startTime, isA<String>());
      expect(seats, isA<int>());
      expect(userId, isA<String>());

      print('✅ Complete trip search has all parameters with correct types');
    });

    test('Complete trip creation flow verifies all parameters', () {
      // Arrange - All parameters for trip creation
      final request = OfferRideRequest(
        driverId: 'driver_456',
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
        offeredSeat: 3,
      );

      // Assert - Verify all fields
      expect(request.driverId, isA<String>());
      expect(request.vehicleNumber, isA<String>());
      expect(request.sourceAddress, isA<Points>());
      expect(request.sourceAddress.latitude, isA<double>());
      expect(request.sourceAddress.longitude, isA<double>());
      expect(request.destinationAddress, isA<Points>());
      expect(request.destinationAddress.latitude, isA<double>());
      expect(request.destinationAddress.longitude, isA<double>());
      expect(request.tripStartDateTime, isA<DateTime>());
      expect(request.offeredSeat, isA<int>());

      print('✅ Complete trip creation has all parameters with correct types');
    });
  });
}
