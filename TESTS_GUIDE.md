# API Integration & Unit Tests Guide

This document explains the comprehensive test suite created to verify server requests and responses.

## Test Files Created

### 1. **integration_test/api_integration_test.dart**
Real API integration tests that call actual backend endpoints.

**Test Groups:**
- **Trip Search - Matching Route**: Tests the main trip search endpoint
  - ✅ Search with valid parameters returns trips
  - ✅ Search with no matches returns empty list
  - ✅ Verifies parameters sent as numbers (not strings)

- **Trip Search - Near Source**: Tests location-based search near source
  - ✅ Returns trips near source location
  - ✅ Verifies results are within radius

- **Trip Search - Near Destination**: Tests location-based search near destination
  - ✅ Returns trips near destination location
  - ✅ Verifies results are within radius

- **Trip Creation - Offer Trip**: Tests trip creation endpoint
  - ✅ Creates trip with valid offer request
  - ✅ Verifies response structure (includes route geometry)
  - ✅ Confirms all required fields are present

- **Driver Trips - Get Active Trips**: Tests driver's trips list
  - ✅ Retrieves active trips for driver
  - ✅ Handles driver with no trips
  - ✅ Verifies response structure

- **Passenger Bookings - Get Active Bookings**: Tests passenger bookings
  - ✅ Retrieves active bookings for passenger
  - ✅ Verifies booking response structure

- **Response Format Verification**: Tests API response wrapper
  - ✅ All responses have ApiResponse wrapper
  - ✅ Contains message and timestamp

### 2. **test/models/trip_model_test.dart**
Unit tests for Trip model parsing and validation.

**Test Groups:**
- **Trip API Response Models**
  - ✅ Trip model parses JSON with correct field names (totalSeats, bookedSeats)
  - ✅ Verifies all fields match backend specification
  - ✅ Available seats calculation is correct

- **Response Wrapper**
  - ✅ ApiResponse handles generic data type
  - ✅ Correctly parses list of trips

- **Trip Search Parameter Validation**
  - ✅ Parameters are numeric types (not strings)
  - ✅ Trip start time is ISO 8601 format
  - ✅ Radius parameters are positive numbers

- **Points Model Validation**
  - ✅ Geographic coordinates are within valid ranges
  - ✅ Place address is not empty

### 3. **test/models/booking_response_test.dart**
Unit tests for Booking response models.

**Test Groups:**
- **Booking Response Models**
  - ✅ DriverTripResponse uses `passengers` field (not `joinedRidersId`)
  - ✅ Handles empty passengers list
  - ✅ PassengerRideResponse has all required fields
  - ✅ Passenger model structure is correct

- **Data Validation**
  - ✅ Passengers count matches booked seats

## Running the Tests

### Run All Unit Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/models/trip_model_test.dart
flutter test test/models/booking_response_test.dart
```

### Run Integration Tests (against real server)
```bash
# Make sure your Flutter app is not already running
flutter drive --target=integration_test/api_integration_test.dart
```

Or for headless testing:
```bash
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/api_integration_test.dart \
  -d emulator-5554
```

### Run Tests with Verbose Output
```bash
flutter test --verbose
```

### Run Tests with Coverage
```bash
flutter test --coverage
# Coverage report will be in coverage/lcov.info
```

## Test Data

The tests use the following test credentials:
- **Base URL**: `http://34.160.91.182`
- **Test Passenger ID**: `rhPRMNYhfAbi82xzbuYvKySEvWw1`
- **Test Driver ID**: `RYiwBWzGQTWhKx8nmhHNuwBQv232`

### Test Locations
- **Source (Marburg, Germany)**
  - Latitude: 50.8090106
  - Longitude: 8.7704695

- **Destination (Frankfurt, Germany)**
  - Latitude: 50.1106444
  - Longitude: 8.6820917

## Expected Results

### Trip Search Test Results
```
✅ Trip search returned X results
✅ Trip response structure verified
✅ Request parameters sent correctly (numbers, not strings)
✅ Near-source search returned X results
✅ Returned trips are within source radius
✅ Near-destination search returned X results
✅ Returned trips have destination within radius
```

### Trip Creation Test Results
```
✅ Trip created successfully with ID: trip_xyz
✅ Trip response structure verified with route geometry
```

### Driver Trips Test Results
```
✅ Retrieved X active trips for driver
✅ Driver trip response structure verified
✅ Empty result handled for driver with no trips
```

### Passenger Bookings Test Results
```
✅ Retrieved X active bookings for passenger
✅ Booking response structure verified
```

### Model Validation Test Results
```
✅ Trip model parses all fields correctly
✅ ApiResponse handles generic data correctly
✅ DriverTripResponse uses passengers field correctly
✅ DriverTripResponse handles empty passengers list correctly
✅ PassengerRideResponse has all required fields
```

## Key Fixes Verified by Tests

1. **Field Names Match Backend Spec**
   - Trip: `totalSeats` (not `offeredSeat`), `bookedSeats` (not `currSeats`)
   - DriverTripResponse: `passengers` (not `joinedRidersId`)

2. **Numeric Parameters Sent Correctly**
   - latitude/longitude sent as doubles, not strings
   - requestedSeats sent as integer, not string
   - Test verifies: `sourceLatitude` is 50.8090106 not "50.8090106"

3. **API Response Wrapper**
   - All responses wrapped in ApiResponse with message and timestamp
   - Data field contains actual response (Trip list, DriverTripResponse, etc.)

4. **Route Information**
   - Trip creation returns route geometry, distance, and duration
   - Used for map display in UI

5. **Passengers List**
   - DriverTripResponse contains passengers array
   - Each passenger has: passengerId, name, email
   - Used to display who booked seats in trip

## Troubleshooting Tests

### If tests timeout
- Increase timeout: Add `timeout: const Timeout(Duration(seconds: 30))`
- Check server connectivity: `ping 34.160.91.182`

### If tests fail with 404
- Verify server is running and accessible
- Check endpoint paths match OpenAPI spec
- Verify Firebase token is valid

### If tests fail with model parsing errors
- Check JSON structure matches model classes
- Verify field names exactly match (case-sensitive)
- Check data types (string vs number)

## Continuous Integration

To add these tests to CI/CD pipeline, use:

```yaml
# GitHub Actions example
- name: Run Flutter Tests
  run: flutter test

- name: Run Integration Tests
  run: flutter drive --target=integration_test/api_integration_test.dart
```

## Performance Metrics

The tests also help identify performance issues:
- Network latency: How long API calls take
- Response parsing: How long JSON parsing takes
- Memory usage: Monitor with `--track-widget-creation`

## Test Coverage

Run coverage analysis:
```bash
flutter test --coverage
# Then install lcov and generate HTML report
genhtml coverage/lcov.info -o coverage/html
```

## Adding New Tests

To add tests for new features:

1. **For new endpoints**: Add test group to `api_integration_test.dart`
2. **For new models**: Add test group to `test/models/`
3. **For new business logic**: Add unit tests to `test/`

Example:
```dart
test('Should verify new feature works correctly', () async {
  // Arrange
  
  // Act
  final response = await someApiService.newFeature();
  
  // Assert
  expect(response.data, isNotNull);
  print('✅ New feature works correctly');
});
```

## References

- **OpenAPI Spec**: [trip-api-spec.json](trip-api-spec.json)
- **API Documentation**: [API_SPECIFICATION.md](API_SPECIFICATION.md)
- **Backend Issues**: [BACKEND_ISSUES.md](BACKEND_ISSUES.md)
