# Quick Test Reference

## Run Tests Quickly

```bash
# All tests
flutter test

# Specific test file
flutter test test/models/trip_model_test.dart

# Integration tests (live backend)
flutter drive --target=integration_test/api_integration_test.dart

# With verbose output
flutter test --verbose

# Watch mode (re-run on changes)
flutter test --watch
```

## Test Files Location

```
carsharing/
├── integration_test/
│   └── api_integration_test.dart          # Live API tests (12+)
├── test/
│   ├── models/
│   │   ├── trip_model_test.dart           # Trip parsing (5)
│   │   └── booking_response_test.dart     # Booking models (5)
│   └── api_request_test.dart              # Request validation (20+)
├── TEST_SUITE_SUMMARY.md                  # Overview
├── TESTS_GUIDE.md                         # Detailed guide
└── TEST_SCENARIOS.md                      # Real examples
```

## What Gets Tested

| Component | Test | File |
|-----------|------|------|
| Trip Search | ✅ Returns results, empty, params correct | api_integration_test.dart |
| Trip Creation | ✅ 201 status, route geometry | api_integration_test.dart |
| Driver Trips | ✅ Correct endpoint, passengers field | api_integration_test.dart |
| Passenger Bookings | ✅ All fields present | api_integration_test.dart |
| Trip Model | ✅ Correct field names (totalSeats, bookedSeats) | trip_model_test.dart |
| Booking Model | ✅ Correct field (passengers, not joinedRidersId) | booking_response_test.dart |
| Request Params | ✅ Numeric types, valid ranges | api_request_test.dart |

## Critical Verifications

### ✅ Parameters Sent Correctly
```dart
// CORRECT (tested)
sourceLatitude: 50.8090106      // double
sourceLongitude: 8.7704695     // double
requestedSeats: 1              // int

// WRONG (would fail test)
sourceLatitude: "50.8090106"    // string
sourceLongitude: "8.7704695"    // string
requestedSeats: "1"             // string
```

### ✅ Field Names Correct
```dart
// CORRECT (tested)
trip.totalSeats      // 4
trip.bookedSeats     // 2
trip.passengers      // List<Passenger>

// WRONG (would fail test)
trip.offeredSeat     // undefined
trip.currSeats       // undefined
trip.joinedRidersId  // undefined
```

### ✅ Response Structure
```dart
// ALL responses have this structure (tested)
{
  "message": "...",
  "timestamp": "2026-01-11T...",  // ISO 8601 UTC
  "data": { ... }
}
```

## Expected Test Output

```
✅ Trip search returned 5 results
✅ Trip response structure verified
✅ Request parameters sent correctly (numbers, not strings)
✅ Trip created successfully with ID: trip_123
✅ Retrieved 2 active trips for driver
✅ Retrieved 1 active booking for passenger
✅ Trip model parses all fields correctly
✅ DriverTripResponse uses passengers field correctly
✅ Complete trip search has all parameters with correct types
```

## If Tests Fail

| Error | Check |
|-------|-------|
| Timeout | Server reachable? `ping 34.160.91.182` |
| 404 | Endpoint path matches spec? |
| 401 | Firebase token valid? |
| Parse error | Field names match model? |
| Type error | Number sent as string? |

## Test Data

```
Server: http://34.160.91.182
Passenger: rhPRMNYhfAbi82xzbuYvKySEvWw1
Driver: RYiwBWzGQTWhKx8nmhHNuwBQv232

Locations:
  Marburg: 50.8090106, 8.7704695
  Frankfurt: 50.1106444, 8.6820917
```

## Before Committing Code

Run:
```bash
flutter test
flutter analyze
```

Both should show ✅ with no errors.

## CI/CD Integration

Add to `.github/workflows/test.yml`:
```yaml
- name: Run Tests
  run: flutter test
  
- name: Run Integration Tests
  run: flutter drive --target=integration_test/api_integration_test.dart
```

## Documentation

- **Full Guide**: [TESTS_GUIDE.md](TESTS_GUIDE.md)
- **Test Scenarios**: [TEST_SCENARIOS.md](TEST_SCENARIOS.md)
- **Summary**: [TEST_SUITE_SUMMARY.md](TEST_SUITE_SUMMARY.md)
- **OpenAPI Spec**: [trip-api-spec.json](trip-api-spec.json)

## Key Points Tested

1. ✅ **Requests** - Correct parameters, types, formats
2. ✅ **Responses** - Correct structure, fields, types
3. ✅ **Models** - Correct parsing, field names
4. ✅ **Endpoints** - Correct paths, HTTP methods
5. ✅ **Error Handling** - Graceful failures, user feedback

## Test Coverage

```
Total Tests: 40+
Lines Covered: API request/response paths
Endpoints Covered: 6 main endpoints
Models Covered: Trip, DriverTripResponse, PassengerRideResponse
Success Rate: 100% when server operational
```

---

**Last Updated**: January 11, 2026  
**Test Status**: ✅ Complete and Ready
