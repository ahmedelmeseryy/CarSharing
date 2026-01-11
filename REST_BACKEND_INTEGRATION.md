# REST Backend Integration Guide

## Overview

This guide walks you through the complete REST backend integration for the Flutter car-sharing app. It replaces Firebase with a microservices REST API running at `http://34.30.27.79:8080`.

## Architecture

```
Presentation Layer (UI)
    ↓
Riverpod Providers (State Management)
    ↓
Repository Pattern (Domain & Data Layers)
    ↓
API Services (HTTP calls)
    ↓
Dio Client (HTTP + Auth + Error Handling)
    ↓
REST Backend (Spring Microservices)
```

## File Structure

```
lib/
├── core/
│   ├── network/
│   │   ├── dio_client.dart          # HTTP client with JWT auth
│   │   ├── api_exceptions.dart      # Custom exception hierarchy
│   │   └── api_response.dart        # Generic response wrapper
│   ├── storage/
│   │   └── secure_storage.dart      # JWT token persistence
│   ├── providers/
│   │   ├── app_providers.dart       # DI & query providers
│   │   └── mutation_providers.dart  # State mutation providers
│   └── pages/
│       └── api_debug_screen.dart    # Testing console
├── features/
│   ├── trip/
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── trip_repository.dart  # Trip interface
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── offer_ride_request.dart
│   │   │   │   ├── offer_ride_response.dart
│   │   │   │   ├── trip.dart
│   │   │   │   └── points.dart
│   │   │   ├── services/
│   │   │   │   └── trip_api_service.dart  # Trip endpoints
│   │   │   └── repositories/
│   │   │       └── trip_repository_impl.dart
│   │   └── presentation/
│   │       └── pages/
│   │           ├── trip_search_example.dart
│   │           └── driver_offer_trip_example.dart
│   └── booking/
│       ├── domain/
│       ├── data/
│       │   ├── models/
│       │   │   ├── booking_requests.dart
│       │   │   └── booking_response.dart
│       │   ├── services/
│       │   │   └── booking_api_service.dart
│       │   └── repositories/
│       │       └── booking_repository_impl.dart
│       └── presentation/
```

## Setup Instructions

### 1. Update pubspec.yaml

Add these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  dio: ^5.3.0
  json_serializable: ^6.7.0
  json_annotation: ^4.8.1
  flutter_secure_storage: ^9.0.0
  logger: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
```

### 2. Generate JSON serialization code

Run this after adding the files:

```bash
flutter pub run build_runner build
```

This generates all the `.g.dart` files for models.

### 3. Initialize Riverpod in main.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

## Core Components

### DioClient: HTTP + Authentication

**Location**: `lib/core/network/dio_client.dart`

Handles:
- Base URL configuration
- JWT token injection from secure storage
- Automatic error mapping
- Request/response logging
- Timeout management

```dart
// Usage in services
final response = await _dioClient.post<OfferRideResponse>(
  '/api/trips/offer',
  data: request.toJson(),
  fromJson: (json) => OfferRideResponse.fromJson(json),
);
```

### TokenStorage: JWT Persistence

**Location**: `lib/core/storage/secure_storage.dart`

Methods:
- `saveTokens(accessToken, refreshToken, userId)` - Save JWT tokens
- `getAccessToken()` - Retrieve access token
- `clearAll()` - Logout

```dart
final storage = TokenStorage();
await storage.saveTokens(accessToken, refreshToken, userId);
final token = await storage.getAccessToken();
```

### Exception Handling

**Location**: `lib/core/network/api_exceptions.dart`

Custom exception types:
- `UnauthorizedException` (401)
- `ForbiddenException` (403)
- `NotFoundException` (404)
- `ServerException` (5xx)
- `NetworkException` (connection errors)

DioClient automatically maps HTTP errors to these.

## API Services

### TripApiService

**Location**: `lib/features/trip/data/services/trip_api_service.dart`

Endpoints:
- `offerTrip(OfferRideRequest)` → POST /api/trips/offer
- `cancelTrip(CancelTripRequest)` → POST /api/trips/cancel
- `getUpcomingTripsForDriver(driverId)` → GET /api/trips/upcoming/driver/{driverId}
- `searchNearSource({lat, lon, radiusKm})` → GET /api/trips/search/near-source
- `searchNearDestination({lat, lon, radiusKm})` → GET /api/trips/search/near-destination
- `searchMatchingRoute({sourceLat, sourceLon, sourceRadiusKm, destLat, destLon, destRadiusKm})` → GET /api/trips/search/matching-route

### BookingApiService

**Location**: `lib/features/booking/data/services/booking_api_service.dart`

Endpoints:
- `joinTrip(JoinTripRequest)` → POST /api/bookings/join
- `cancelBooking(CancelTripRequest)` → POST /api/bookings/cancel
- `getUpcomingBookingsForPassenger(passengerId)` → GET /api/bookings/upcoming/passenger/{passengerId}

## Repository Pattern

Repositories separate API calls from business logic:

```dart
// Domain interface (lib/features/trip/domain/repositories/trip_repository.dart)
abstract class ITripRepository {
  Future<List<Trip>> searchMatchingRoute({...});
  Future<OfferRideResponse> offerTrip(OfferRideRequest request);
  // ...
}

// Data implementation (lib/features/trip/data/repositories/trip_repository_impl.dart)
class TripRepositoryImpl implements ITripRepository {
  final TripApiService _apiService;
  
  @override
  Future<List<Trip>> searchMatchingRoute({...}) async {
    final response = await _apiService.searchMatchingRoute(...);
    if (response.isSuccess) return response.data ?? [];
    throw Exception(response.errorMessage);
  }
}
```

## Riverpod Providers

### Setup Providers

```dart
// lib/core/providers/app_providers.dart

// Singleton instances
final secureStorageProvider = Provider<TokenStorage>(...);
final dioClientProvider = Provider<DioClient>(...);

// Services
final tripApiServiceProvider = Provider<TripApiService>(...);

// Repositories
final tripRepositoryProvider = Provider<ITripRepository>(...);
```

### Query Providers (Reading Data)

```dart
// Fetch trips matching a route
final searchMatchingRouteProvider = FutureProvider.family<List, (...)>((ref, params) async {
  return ref.watch(tripRepositoryProvider).searchMatchingRoute(...);
});

// Watch provider in UI
final trips = ref.watch(searchMatchingRouteProvider((
  sourceLat: 52.52,
  // ... other params
)));

// Handle loading/error/success
trips.when(
  data: (tripsList) => ...,
  loading: () => ...,
  error: (error, stack) => ...,
);
```

### Mutation Providers (Writing Data)

```dart
// lib/core/providers/mutation_providers.dart

class JoinTripNotifier extends StateNotifier<AsyncValue<PassengerRideResponse>> {
  // ...
  Future<void> joinTrip(JoinTripRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(bookingRepositoryProvider).joinTrip(request),
    );
  }
}

final joinTripProvider = StateNotifierProvider.autoDispose<JoinTripNotifier, AsyncValue<PassengerRideResponse?>>(
  (ref) => JoinTripNotifier(ref),
);
```

## UI Integration Examples

### 1. Passenger: Search & Book a Trip

See: `lib/features/trip/presentation/pages/trip_search_example.dart`

```dart
class TripSearchExample extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(searchMatchingRouteProvider(params));
    
    return trips.when(
      data: (tripsList) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(...),
    );
  }
}

// In booking screen
final notifier = ref.read(joinTripProvider.notifier);
await notifier.joinTrip(JoinTripRequest(...));
```

### 2. Driver: Offer a Trip

See: `lib/features/trip/presentation/pages/driver_offer_trip_example.dart`

```dart
class OfferTripExample extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerState = ref.watch(offerTripProvider);
    
    return offerState.when(
      data: (response) => ConfirmationUI(...),
      loading: () => LoadingSpinner(),
      error: (err, stack) => ErrorUI(...),
    );
  }
}

// Submit
final notifier = ref.read(offerTripProvider.notifier);
await notifier.offerTrip(OfferRideRequest(...));
```

### 3. Testing: API Debug Console

See: `lib/core/pages/api_debug_screen.dart`

Quick test buttons for each endpoint with request/response inspection.

## Common Patterns

### Handling Loading States

```dart
// ✅ Do this
final data = ref.watch(provider);
data.when(
  data: (value) => ...,
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error),
);

// ❌ Don't do this
if (data.isLoading) { ... } // isLoading doesn't exist on AsyncValue
```

### Refreshing Data

```dart
// Invalidate provider to trigger refetch
ref.refresh(searchMatchingRouteProvider(params));

// Or refresh all providers
ref.refresh(tripRepositoryProvider);
```

### Error Handling

All exceptions are caught and wrapped in `AsyncValue`:

```dart
final data = ref.watch(provider);
if (data.hasError) {
  final error = data.error; // Exception
  print('Error: $error');
}
```

### Passing Parameters to Providers

```dart
// Use .family for parameterized providers
final provider = FutureProvider.family<Type, (param1, param2, ...)>(...);

ref.watch(provider((
  sourceLat: 52.52,
  sourceLon: 13.405,
  // ...
)));
```

## Authentication Flow

1. **Login** (not shown here, integrate with existing auth)
   ```dart
   final tokens = await loginAPI(...);
   await ref.read(secureStorageProvider).saveTokens(
     tokens.accessToken,
     tokens.refreshToken,
     tokens.userId,
   );
   ```

2. **API calls** automatically inject JWT from secure storage
   ```dart
   // DioClient intercepts and adds:
   // Authorization: Bearer <accessToken>
   ```

3. **Logout**
   ```dart
   await ref.read(secureStorageProvider).clearAll();
   ```

## Debugging

### Enable Logging

DioClient logs all requests/responses via the `logger` package:

```dart
final dioClient = DioClient();
// Logs are printed to console automatically
```

### API Debug Screen

Navigate to `/api-debug` route to test endpoints manually:

```dart
// In main.dart routes
'/api-debug': (context) => ApiDebugScreen(),
```

### Inspect Request/Response

```dart
// Enable verbose logging in DioClient
dioClient.dio.interceptors.add(
  LogInterceptor(
    requestBody: true,
    responseBody: true,
    responseHeader: true,
  ),
);
```

## Common Issues

### Issue: "Null check operator used on a null value"

**Cause**: Trying to access `response.data!` when `response.data` is null

**Fix**: Check with `.when()` or `.isSuccess` before accessing

```dart
// ❌ Wrong
return response.data!.tripId;

// ✅ Correct
if (response.isSuccess && response.data != null) {
  return response.data!.tripId;
}
```

### Issue: "Unhandled Exception: UnauthorizedException"

**Cause**: JWT token expired or invalid

**Fix**: 
1. Check token in secure storage: `TokenStorage().getAccessToken()`
2. Re-login if token is null
3. Implement token refresh endpoint

### Issue: "Cannot hit backend - Connection refused"

**Cause**: Backend server is down or baseUrl is wrong

**Fix**:
1. Check backend is running: `curl http://34.30.27.79:8080/v3/api-docs/trip`
2. Verify baseUrl in `DioClient`: should be `http://34.30.27.79:8080`
3. On emulator, use `10.0.2.2` instead of `localhost`

## Next Steps

1. **Implement Authentication**
   - Add login/logout endpoints
   - Integrate with existing Firebase Auth
   - Store tokens in `TokenStorage`

2. **Build Missing UI Pages**
   - Ride history/reviews
   - Driver profile/ratings
   - Payment integration

3. **Add Error Recovery**
   - Implement token refresh logic
   - Retry logic for failed requests
   - Offline mode with caching

4. **Testing**
   - Write unit tests for repositories
   - Integration tests for API services
   - Widget tests for UI screens

5. **Production Checklist**
   - Remove debug logging
   - Enable SSL certificate pinning
   - Add analytics/crash reporting
   - Performance profiling

## API Reference

### Trip Service

**POST /api/trips/offer**
- Request: `OfferRideRequest`
- Response: `ApiResponse<OfferRideResponse>`

**POST /api/trips/cancel**
- Request: `CancelTripRequest`
- Response: `ApiResponse<String>`

**GET /api/trips/upcoming/driver/{driverId}**
- Response: `ApiResponse<List<DriverTripResponse>>`

**GET /api/trips/search/near-source**
- Query params: `sourceLat, sourceLon, radiusKm, requestedSeats, rideStartTime`
- Response: `ApiResponse<List<Trip>>`

**GET /api/trips/search/near-destination**
- Query params: `destLat, destLon, radiusKm, requestedSeats, rideStartTime`
- Response: `ApiResponse<List<Trip>>`

**GET /api/trips/search/matching-route**
- Query params: `sourceLat, sourceLon, sourceRadiusKm, destLat, destLon, destRadiusKm, rideStartTime, requestedSeats, effectiveUserId`
- Response: `ApiResponse<List<Trip>>`

### Booking Service

**POST /api/bookings/join**
- Request: `JoinTripRequest`
- Response: `ApiResponse<PassengerRideResponse>`

**POST /api/bookings/cancel**
- Request: `CancelTripRequest`
- Response: `ApiResponse<String>`

**GET /api/bookings/upcoming/passenger/{passengerId}**
- Response: `ApiResponse<List<PassengerRideResponse>>`

## Resources

- [Riverpod Documentation](https://riverpod.dev)
- [Dio Documentation](https://pub.dev/packages/dio)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [JSON Serialization](https://dart.dev/guides/json)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)
