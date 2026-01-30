# Test Suite Summary

## Overview
A comprehensive test suite has been created to ensure the server receives correct requests and returns the expected responses.

## Test Files Created

| File | Purpose | Tests |
|------|---------|-------|
| `integration_test/api_integration_test.dart` | **Real API Integration** - Tests against live backend | 12+ tests |
| `test/models/trip_model_test.dart` | **Trip Model Parsing** - Verifies JSON parsing with correct field names | 5 tests |
| `test/models/booking_response_test.dart` | **Booking Model Parsing** - Verifies booking response models | 5 tests |
| `test/api_request_test.dart` | **Request Parameters** - Validates all API request parameters and types | 20+ tests |

**Total: 40+ comprehensive tests**

## What Each Test Verifies

### 1. Integration Tests (Live Backend)

#### Trip Search Tests
- ✅ Search returns correct trips when they exist
- ✅ Search returns empty list when no matches
- ✅ Parameters sent as **numbers** (not strings) - **KEY FIX**
- ✅ Source-based search returns trips within radius
- ✅ Destination-based search returns trips within radius

#### Trip Creation Tests
- ✅ Trip created successfully returns 201
- ✅ Response includes all required fields:
  - tripId
  - vehicleNumber
  - sourceAddress with latitude/longitude
  - destinationAddress with latitude/longitude
  - **routeGeometry** (used for maps)
  - routeDistance
  - routeDuration
  - tripTimezone
- ✅ totalSeats and bookedSeats fields present (not offeredSeat/currSeats)

#### Driver Trips Tests
- ✅ Returns list of active trips for driver
- ✅ Endpoint is correct: `/api/trips/active/driver/{id}` (not /upcoming/)
- ✅ Each trip includes **passengers** field (not joinedRidersId)
- ✅ Handles driver with no trips gracefully

#### Passenger Bookings Tests
- ✅ Returns list of active bookings for passenger
- ✅ Response includes required fields:
  - rideId
  - tripId
  - driverId
  - sourceLatitude/sourceLongitude
  - destinationLatitude/destinationLongitude
  - rideStatus

#### Response Format Tests
- ✅ All responses wrapped in ApiResponse:
  ```json
  {
    "message": "...",
    "timestamp": "2026-01-11T...",
    "data": { ... }
  }
  ```

### 2. Model Tests (Trip)

#### Field Name Verification
- ✅ Trip model uses `totalSeats` (not `offeredSeat`) - **CRITICAL FIX**
- ✅ Trip model uses `bookedSeats` (not `currSeats`) - **CRITICAL FIX**
- ✅ availableSeats calculated correctly
- ✅ All geographic coordinates within valid ranges

#### JSON Parsing
- ✅ Correctly parses OpenAPI spec response
- ✅ Handles all coordinate fields
- ✅ ISO 8601 datetime parsing works

### 3. Booking Model Tests

#### DriverTripResponse
- ✅ Uses `passengers` field (not `joinedRidersId`) - **CRITICAL FIX**
- ✅ Passengers is array with structure:
  ```dart
  {
    passengerId: string,
    name: string,
    email: string
  }
  ```
- ✅ Handles empty passengers list
- ✅ Booking count matches passengers length
- ✅ routeDistanceInKm present for map display

#### PassengerRideResponse
- ✅ All required fields present
- ✅ Coordinates are doubles
- ✅ Status is string

### 4. Request Parameter Tests

#### Type Validation
- ✅ `sourceLatitude`: double (NOT string "50.8090106")
- ✅ `sourceLongitude`: double (NOT string "8.7704695")
- ✅ `sourceRadiusKm`: double (NOT string)
- ✅ `requestedSeats`: int (NOT string "1")
- ✅ Other parameters: correct types

#### Value Range Validation
- ✅ Latitude: -90 to +90
- ✅ Longitude: -180 to +180
- ✅ Radius: positive number
- ✅ Seats: positive integer

#### Format Validation
- ✅ DateTime: ISO 8601 UTC format (ends with 'Z')
- ✅ IDs: non-empty strings
- ✅ Addresses: non-empty strings
- ✅ Vehicle number: non-empty string

## Test Execution Commands

### Run All Tests
```bash
flutter test
```

### Run Specific Test Group
```bash
# Trip model tests
flutter test test/models/trip_model_test.dart

# Booking model tests
flutter test test/models/booking_response_test.dart

# Request parameter tests
flutter test test/api_request_test.dart
```

### Run Integration Tests (Real Backend)
```bash
# Run against live server
flutter drive --target=integration_test/api_integration_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

## Key Fixes Verified by Tests

### Fix 1: Field Names Match Backend
**Before:** `trip.offeredSeat`, `trip.currSeats`  
**After:** `trip.totalSeats`, `trip.bookedSeats`  
**Test Verification:** trip_model_test.dart

### Fix 2: Parameters Sent as Numbers
**Before:** 
```dart
queryParams: {
  'sourceLatitude': 50.8090106.toString(),  // Wrong!
  'sourceLongitude': 8.7704695.toString(),  // Wrong!
}
```
**After:**
```dart
queryParams: {
  'sourceLatitude': 50.8090106,  // Correct!
  'sourceLongitude': 8.7704695,  // Correct!
}
```
**Test Verification:** api_request_test.dart, api_integration_test.dart

### Fix 3: Correct Endpoint Path
**Before:** `/api/trips/upcoming/driver/{id}`  
**After:** `/api/trips/active/driver/{id}`  
**Test Verification:** api_integration_test.dart

### Fix 4: Passengers Field
**Before:** `joinedRidersId: List<String>`  
**After:** `passengers: List<Passenger>`  
**Test Verification:** booking_response_test.dart

## Test Results Expected Output

When running all tests successfully, you should see:

```
✅ Trip search returned N results
✅ Trip response structure verified
✅ Request parameters sent correctly (numbers, not strings)
✅ Trip created successfully with ID: trip_xyz
✅ Trip response structure verified with route geometry
✅ Retrieved N active trips for driver
✅ Retrieved N active bookings for passenger
✅ Trip model parses all fields correctly
✅ DriverTripResponse uses passengers field correctly
✅ All trip search parameters are correct types
✅ OfferRideRequest serializes correctly
✅ Complete trip search has all parameters with correct types
```

## Test Coverage Goals

| Area | Coverage |
|------|----------|
| Trip Search | 100% |
| Trip Creation | 100% |
| Driver Trips | 100% |
| Passenger Bookings | 100% |
| Model Parsing | 100% |
| Parameter Types | 100% |
| Response Format | 100% |

## Continuous Monitoring

These tests should be run:
1. **Before each commit** - Verify no regressions
2. **In CI/CD pipeline** - Automated verification
3. **Before releases** - Ensure production readiness
4. **After backend changes** - Verify compatibility

## Adding New Tests

When adding new features, create corresponding tests:

1. **New API endpoint?** → Add test in `api_integration_test.dart`
2. **New model?** → Add test in `test/models/`
3. **New business logic?** → Add unit test
4. **New parameter?** → Add validation test in `test/api_request_test.dart`

Template:
```dart
test('Should verify new feature', () async {
  // Arrange
  
  // Act
  
  // Assert
  expect(result, expected);
  print('✅ New feature works correctly');
});
```

## Documentation References

- **OpenAPI Spec**: [trip-api-spec.json](trip-api-spec.json)
- **Full Test Guide**: [TESTS_GUIDE.md](TESTS_GUIDE.md)
- **API Integration**: [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
- **Backend Status**: [BACKEND_ISSUES.md](BACKEND_ISSUES.md)

## Quick Status Check

All tests should verify:
- ✅ Server receives correct request format (types, parameters)
- ✅ Server returns correct response structure (fields, types)
- ✅ All field names match OpenAPI specification exactly
- ✅ All numeric values sent as numbers (not strings)
- ✅ All responses wrapped in ApiResponse with message/timestamp
- ✅ All geographic data within valid ranges
- ✅ All datetime in ISO 8601 UTC format
