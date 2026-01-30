# API Test Scenarios & Examples

This document provides concrete examples of test scenarios to verify server requests and responses.

## Scenario 1: User Search for Trip (Happy Path)

### Request Sent to Server
```
GET /api/trips/search/matching-route?
  sourceLatitude=50.8090106&
  sourceLongitude=8.7704695&
  sourceRadiusKm=10.0&
  destinationLatitude=50.1106444&
  destinationLongitude=8.6820917&
  destinationRadiusKm=10.0&
  rideStartTime=2026-04-04T14:00:00Z&
  requestedSeats=1&
  effectiveUserId=rhPRMNYhfAbi82xzbuYvKySEvWw1

Headers:
  Authorization: Bearer {firebase_token}
  Content-Type: application/json
```

### Key Test Verifications
- ✅ Parameters are **numbers** not strings:
  - `sourceLatitude=50.8090106` ← double
  - `requestedSeats=1` ← int
- ✅ DateTime is ISO 8601 UTC: `2026-04-04T14:00:00Z`
- ✅ Coordinates within valid ranges (-90 to 90, -180 to 180)
- ✅ Radius is positive: 10.0

### Expected Response (200 OK)
```json
{
  "message": "Matching trips found",
  "timestamp": "2026-01-11T10:30:45Z",
  "data": [
    {
      "tripId": "trip_123",
      "driverId": "driver_456",
      "vehicleNumber": "ABC123",
      "sourceAddress": {
        "latitude": 50.8090106,
        "longitude": 8.7704695,
        "placeAddress": "Marburg, Germany"
      },
      "destinationAddress": {
        "latitude": 50.1106444,
        "longitude": 8.6820917,
        "placeAddress": "Frankfurt, Germany"
      },
      "tripStartDateTime": "2026-04-04T14:00:00Z",
      "tripTimezone": "Europe/Berlin",
      "totalSeats": 4,        ← IMPORTANT: NOT offeredSeat
      "bookedSeats": 2,       ← IMPORTANT: NOT currSeats
      "availableSeats": 2,
      "tripStatus": "ACTIVE",
      "routeGeometry": "polyline...",
      "routeDistance": 75.5,
      "routeDuration": 3600
    }
  ]
}
```

### Test Code
```dart
test('Should search for trips and get results', () async {
  final response = await tripApiService.searchMatchingRoute(
    sourceLat: 50.8090106,        // Verify: double, not string
    sourceLon: 8.7704695,         // Verify: double, not string
    sourceRadiusKm: 10.0,         // Verify: positive double
    destLat: 50.1106444,          // Verify: in range -90..90
    destLon: 8.6820917,           // Verify: in range -180..180
    rideStartTime: '2026-04-04T14:00:00Z',  // Verify: ISO 8601 UTC
    requestedSeats: 1,            // Verify: int, positive
    effectiveUserId: 'rhPRMNYhfAbi82xzbuYvKySEvWw1',
  );

  // Verify response structure
  expect(response.message, contains('Matching'));
  expect(response.timestamp, isNotNull);
  expect(response.data, isA<List<Trip>>());
  
  // Verify first trip structure
  final trip = response.data!.first;
  expect(trip.totalSeats, equals(4));  // NOT offeredSeat
  expect(trip.bookedSeats, equals(2)); // NOT currSeats
  expect(trip.availableSeats, equals(2));
  expect(trip.sourceAddress.latitude, equals(50.8090106));
  expect(trip.destinationAddress.latitude, equals(50.1106444));
  
  print('✅ Trip search works correctly');
});
```

---

## Scenario 2: Driver Creates New Trip (Happy Path)

### Request Sent to Server
```
POST /api/trips/offer

Headers:
  Authorization: Bearer {firebase_token}
  Content-Type: application/json

Body:
{
  "driverId": "RYiwBWzGQTWhKx8nmhHNuwBQv232",
  "vehicleNumber": "XYZ789",
  "sourceAddress": {
    "latitude": 50.8090106,
    "longitude": 8.7704695,
    "placeAddress": "Marburg, Germany"
  },
  "destinationAddress": {
    "latitude": 50.1106444,
    "longitude": 8.6820917,
    "placeAddress": "Frankfurt, Germany"
  },
  "tripStartDateTime": "2026-04-04T14:00:00Z",
  "offeredSeat": 3
}
```

### Key Test Verifications
- ✅ All coordinate values are numbers: `50.8090106` not `"50.8090106"`
- ✅ DateTime is ISO 8601 UTC
- ✅ offeredSeat is positive integer
- ✅ IDs and addresses are strings
- ✅ All required fields present

### Expected Response (201 Created)
```json
{
  "message": "Trip created successfully",
  "timestamp": "2026-01-11T10:31:00Z",
  "data": {
    "tripId": "trip_789",
    "driverId": "RYiwBWzGQTWhKx8nmhHNuwBQv232",
    "vehicleNumber": "XYZ789",
    "sourceAddress": {
      "latitude": 50.8090106,
      "longitude": 8.7704695,
      "placeAddress": "Marburg, Germany"
    },
    "destinationAddress": {
      "latitude": 50.1106444,
      "longitude": 8.6820917,
      "placeAddress": "Frankfurt, Germany"
    },
    "tripStartDateTime": "2026-04-04T14:00:00Z",
    "tripTimezone": "Europe/Berlin",
    "totalSeats": 3,
    "bookedSeats": 0,
    "availableSeats": 3,
    "tripStatus": "ACTIVE",
    "routeGeometry": "polyline...",
    "routeDistance": 75.5,
    "routeDuration": 3600
  }
}
```

### Test Code
```dart
test('Should create trip successfully', () async {
  final request = OfferRideRequest(
    driverId: 'RYiwBWzGQTWhKx8nmhHNuwBQv232',
    vehicleNumber: 'XYZ789',
    sourceAddress: const Points(
      latitude: 50.8090106,      // Verify: double
      longitude: 8.7704695,      // Verify: double
      placeAddress: 'Marburg, Germany',
    ),
    destinationAddress: const Points(
      latitude: 50.1106444,      // Verify: double
      longitude: 8.6820917,      // Verify: double
      placeAddress: 'Frankfurt, Germany',
    ),
    tripStartDateTime: '2026-04-04T14:00:00Z',  // Verify: ISO 8601
    offeredSeat: 3,              // Verify: positive int
  );

  final response = await tripApiService.offerTrip(request);

  // Verify response
  expect(response.message, contains('created successfully'));
  expect(response.data?.tripId, isNotNull);
  expect(response.data?.totalSeats, equals(3));
  expect(response.data?.bookedSeats, equals(0));
  expect(response.data?.routeGeometry, isNotNull);
  
  print('✅ Trip creation works correctly');
});
```

---

## Scenario 3: View Created Trips as Driver

### Request Sent to Server
```
GET /api/trips/active/driver/RYiwBWzGQTWhKx8nmhHNuwBQv232

Headers:
  Authorization: Bearer {firebase_token}
  Content-Type: application/json
```

### Key Test Verifications
- ✅ Endpoint is correct: `/active/` (not `/upcoming/`)
- ✅ Driver ID is provided
- ✅ Status code is 200

### Expected Response (200 OK)
```json
{
  "message": "Active trips retrieved",
  "timestamp": "2026-01-11T10:32:00Z",
  "data": [
    {
      "tripId": "trip_789",
      "driverId": "RYiwBWzGQTWhKx8nmhHNuwBQv232",
      "vehicleNumber": "XYZ789",
      "sourceAddress": { ... },
      "destinationAddress": { ... },
      "tripStartDateTime": "2026-04-04T14:00:00Z",
      "tripTimezone": "Europe/Berlin",
      "totalSeats": 3,
      "bookedSeats": 1,
      "availableSeats": 2,
      "tripStatus": "ACTIVE",
      "passengers": [                    ← IMPORTANT: NOT joinedRidersId
        {
          "passengerId": "passenger_1",
          "name": "John Doe",
          "email": "john@example.com"
        }
      ],
      "routeDistanceInKm": 75.5
    }
  ]
}
```

### Test Code
```dart
test('Should get active trips for driver', () async {
  const driverId = 'RYiwBWzGQTWhKx8nmhHNuwBQv232';
  
  final response = await tripApiService.getUpcomingTripsForDriver(driverId);

  // Verify response
  expect(response.data, isA<List>());
  
  // Verify first trip structure
  final trip = response.data!.first;
  expect(trip.driverId, equals(driverId));
  expect(trip.totalSeats, equals(3));
  expect(trip.bookedSeats, equals(1));
  expect(trip.availableSeats, equals(2));
  
  // VERIFY: passengers field exists (not joinedRidersId)
  expect(trip.passengers, isNotNull);
  expect(trip.passengers, isA<List>());
  expect(trip.passengers?.length, equals(1));
  expect(trip.passengers?.first.passengerId, equals('passenger_1'));
  expect(trip.passengers?.first.name, equals('John Doe'));
  
  print('✅ Driver trips display works correctly');
});
```

---

## Scenario 4: Passenger Books a Seat

### Request Sent to Server
```
POST /api/bookings/join

Headers:
  Authorization: Bearer {firebase_token}
  Content-Type: application/json

Body:
{
  "tripId": "trip_789",
  "passengerId": "rhPRMNYhfAbi82xzbuYvKySEvWw1",
  "seatsToBook": 1
}
```

### Expected Response (201 Created)
```json
{
  "message": "Booking successful",
  "timestamp": "2026-01-11T10:33:00Z",
  "data": {
    "rideId": "ride_123",
    "tripId": "trip_789",
    "passengerId": "rhPRMNYhfAbi82xzbuYvKySEvWw1",
    "driverId": "RYiwBWzGQTWhKx8nmhHNuwBQv232",
    "sourceLatitude": 50.8090106,
    "sourceLongitude": 8.7704695,
    "destinationLatitude": 50.1106444,
    "destinationLongitude": 8.6820917,
    "rideStartTime": "2026-04-04T14:00:00Z",
    "rideStatus": "CONFIRMED",
    "seatsBooked": 1
  }
}
```

### Test Code
```dart
test('Should book a ride successfully', () async {
  final response = await bookingApiService.joinRide(
    tripId: 'trip_789',
    passengerId: 'rhPRMNYhfAbi82xzbuYvKySEvWw1',
    seatsToBook: 1,
  );

  // Verify response
  expect(response.data?.rideId, isNotNull);
  expect(response.data?.tripId, equals('trip_789'));
  expect(response.data?.seatsBooked, equals(1));
  expect(response.data?.rideStatus, equals('CONFIRMED'));
  expect(response.data?.sourceLatitude, isA<double>());
  expect(response.data?.sourceLongitude, isA<double>());
  
  print('✅ Booking works correctly');
});
```

---

## Scenario 5: Error Case - Invalid Parameters

### Request with Invalid Parameters
```
GET /api/trips/search/matching-route?
  sourceLatitude=50.8090106&
  sourceLongitude=invalid&          ← ERROR: not a number
  sourceRadiusKm=10.0&
  destinationLatitude=50.1106444&
  destinationLongitude=8.6820917&
  destinationRadiusKm=10.0&
  rideStartTime=2026-04-04T14:00:00Z&
  requestedSeats=1&
  effectiveUserId=test_user
```

### Expected Response (400 Bad Request)
```json
{
  "message": "Invalid request parameters",
  "timestamp": "2026-01-11T10:34:00Z",
  "data": null
}
```

### Test Code
```dart
test('Should handle invalid parameters gracefully', () async {
  expect(
    () => tripApiService.searchMatchingRoute(
      sourceLat: 50.8090106,
      sourceLon: double.parse('invalid'), // This will throw
      sourceRadiusKm: 10.0,
      destLat: 50.1106444,
      destLon: 8.6820917,
      destRadiusKm: 10.0,
      rideStartTime: '2026-04-04T14:00:00Z',
      requestedSeats: 1,
      effectiveUserId: 'test_user',
    ),
    throwsException,
  );
  
  print('✅ Error handling works correctly');
});
```

---

## Scenario 6: Edge Case - Search with No Results

### Request
```
GET /api/trips/search/matching-route?
  sourceLatitude=-90.0&
  sourceLongitude=-180.0&
  sourceRadiusKm=1.0&
  destinationLatitude=90.0&
  destinationLongitude=180.0&
  destinationRadiusKm=1.0&
  rideStartTime=2026-04-04T14:00:00Z&
  requestedSeats=1&
  effectiveUserId=test_user
```

### Expected Response (200 OK, Empty List)
```json
{
  "message": "No matching trips found",
  "timestamp": "2026-01-11T10:35:00Z",
  "data": []
}
```

### Test Code
```dart
test('Should handle search with no results', () async {
  final response = await tripApiService.searchMatchingRoute(
    sourceLat: -90.0,
    sourceLon: -180.0,
    sourceRadiusKm: 1.0,
    destLat: 90.0,
    destLon: 180.0,
    destRadiusKm: 1.0,
    rideStartTime: '2026-04-04T14:00:00Z',
    requestedSeats: 1,
    effectiveUserId: 'test_user',
  );

  // Verify empty result handled gracefully
  expect(response.data, isNotNull);
  expect(response.data, isEmpty);
  
  print('✅ Empty results handled correctly');
});
```

---

## Testing Checklist

Before going live, verify:

- [ ] **Trip Search**
  - [ ] Returns results when trips exist
  - [ ] Returns empty list when no matches
  - [ ] Parameters sent as numbers (not strings)
  - [ ] Uses correct field names (totalSeats, bookedSeats)

- [ ] **Trip Creation**
  - [ ] Returns 201 status
  - [ ] Returns complete trip data with geometry
  - [ ] Timezone included in response
  - [ ] Route distance/duration calculated

- [ ] **Driver Trips**
  - [ ] Uses `/active/` endpoint (not `/upcoming/`)
  - [ ] Returns passengers array
  - [ ] Each passenger has passengerId, name, email

- [ ] **Passenger Bookings**
  - [ ] Returns active bookings
  - [ ] Includes all required coordinates and times
  - [ ] Status is correct

- [ ] **Error Handling**
  - [ ] Invalid parameters handled gracefully
  - [ ] Empty results don't crash app
  - [ ] Network errors caught properly
  - [ ] Response errors displayed to user

- [ ] **Response Format**
  - [ ] All responses wrapped in ApiResponse
  - [ ] Message field present and meaningful
  - [ ] Timestamp in ISO 8601 UTC
  - [ ] Data field contains actual response

---

## Performance Benchmarks

Expected response times:
- Trip search: < 2 seconds
- Trip creation: < 3 seconds
- Get driver trips: < 1 second
- Get bookings: < 1 second

Track with tests:
```dart
test('Trip search should complete within 2 seconds', () async {
  final stopwatch = Stopwatch()..start();
  
  await tripApiService.searchMatchingRoute(...);
  
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(2000));
  print('Response time: ${stopwatch.elapsedMilliseconds}ms');
});
```
