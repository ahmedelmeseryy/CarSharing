import 'package:flutter_test/flutter_test.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';
import 'package:carsharing/features/trip/data/models/points.dart';

void main() {
  group('Booking Response Models', () {
    test('DriverTripResponse should use passengers field, not joinedRidersId',
        () {
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
        'tripStartDateTime': '2026-04-04T14:00:00Z',
        'tripTimezone': 'Europe/Berlin',
        'totalSeats': 4,
        'bookedSeats': 2,
        'availableSeats': 2,
        'tripStatus': 'ACTIVE',
        'passengers': [
          {
            'passengerId': 'passenger_1',
            'name': 'John Doe',
            'email': 'john@example.com'
          },
          {
            'passengerId': 'passenger_2',
            'name': 'Jane Smith',
            'email': 'jane@example.com'
          }
        ],
        'routeDistanceInKm': 75.5,
      };

      // Act
      final driverTripResponse = DriverTripResponse.fromJson(json);

      // Assert - Verify passengers field exists and is used correctly
      expect(driverTripResponse.tripId, equals('trip_123'));
      expect(driverTripResponse.driverId, equals('driver_456'));
      expect(driverTripResponse.totalSeats, equals(4));
      expect(driverTripResponse.bookedSeats, equals(2));
      expect(driverTripResponse.availableSeats, equals(2));
      expect(driverTripResponse.passengers, isNotNull);
      expect(driverTripResponse.passengers, isA<List>());
      expect(driverTripResponse.passengers?.length, equals(2));
      expect(driverTripResponse.passengers?.first.passengerId, equals('passenger_1'));
      expect(driverTripResponse.routeDistanceInKm, equals(75.5));
      print('✅ DriverTripResponse uses passengers field correctly');
    });

    test('DriverTripResponse should handle empty passengers list', () {
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
        'tripStartDateTime': '2026-04-04T14:00:00Z',
        'tripTimezone': 'Europe/Berlin',
        'totalSeats': 4,
        'bookedSeats': 0,
        'availableSeats': 4,
        'tripStatus': 'ACTIVE',
        'passengers': [],
        'routeDistanceInKm': 75.5,
      };

      // Act
      final driverTripResponse = DriverTripResponse.fromJson(json);

      // Assert
      expect(driverTripResponse.passengers, isNotNull);
      expect(driverTripResponse.passengers, isEmpty);
      print('✅ DriverTripResponse handles empty passengers list correctly');
    });

    test('PassengerRideResponse should have all required fields', () {
      // Arrange
      final json = {
        'rideId': 'ride_123',
        'tripId': 'trip_456',
        'passengerId': 'passenger_789',
        'driverId': 'driver_321',
        'sourceLatitude': 50.8090106,
        'sourceLongitude': 8.7704695,
        'destinationLatitude': 50.1106444,
        'destinationLongitude': 8.6820917,
        'rideStartTime': '2026-04-04T14:00:00Z',
        'rideStatus': 'CONFIRMED',
        'seatsBooked': 1,
      };

      // Act
      final passengerRide = PassengerRideResponse.fromJson(json);

      // Assert
      expect(passengerRide.rideId, equals('ride_123'));
      expect(passengerRide.tripId, equals('trip_456'));
      expect(passengerRide.passengerId, equals('passenger_789'));
      expect(passengerRide.driverId, equals('driver_321'));
      expect(passengerRide.sourceLatitude, equals(50.8090106));
      expect(passengerRide.sourceLongitude, equals(8.7704695));
      expect(passengerRide.destinationLatitude, equals(50.1106444));
      expect(passengerRide.destinationLongitude, equals(8.6820917));
      expect(passengerRide.rideStatus, equals('CONFIRMED'));
      expect(passengerRide.seatsBooked, equals(1));
      print('✅ PassengerRideResponse has all required fields');
    });

    test('Passenger data class should have required fields', () {
      // This test verifies the Passenger model structure
      final passenger = Passenger(
        passengerId: 'passenger_1',
        name: 'John Doe',
        email: 'john@example.com',
      );

      expect(passenger.passengerId, isNotNull);
      expect(passenger.name, isNotNull);
      expect(passenger.email, isNotNull);
      print('✅ Passenger model has correct structure');
    });

    test('DriverTripResponse booking count should match passengers length',
        () {
      // Arrange
      final driverTrip = DriverTripResponse(
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
        tripStartDateTime: '2026-04-04T14:00:00Z',
        tripTimezone: 'Europe/Berlin',
        totalSeats: 4,
        bookedSeats: 2,
        availableSeats: 2,
        tripStatus: 'ACTIVE',
        passengers: [
          Passenger(
            passengerId: 'p1',
            name: 'John',
            email: 'john@example.com',
          ),
          Passenger(
            passengerId: 'p2',
            name: 'Jane',
            email: 'jane@example.com',
          ),
        ],
        routeDistanceInKm: 75.5,
      );

      // Assert
      expect(driverTrip.passengers?.length, equals(driverTrip.bookedSeats));
      print('✅ Passengers count matches booked seats');
    });
  });
}
