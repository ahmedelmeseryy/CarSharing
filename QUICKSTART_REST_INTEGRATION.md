# Quick Start: REST Backend Integration

## TL;DR - Get Running in 5 Minutes

### 1️⃣ Add Dependencies to pubspec.yaml

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  dio: ^5.3.0
  json_annotation: ^4.8.1
  flutter_secure_storage: ^9.0.0
  logger: ^2.0.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
```

### 2️⃣ Run Build Runner

This generates all the `.g.dart` files for JSON serialization:

```bash
flutter pub run build_runner build
```

### 3️⃣ Wrap App with ProviderScope

In `main.dart`:

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

### 4️⃣ Use in Your UI

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Search for trips
    final tripsAsync = ref.watch(
      searchMatchingRouteProvider((
        sourceLat: 52.52,
        sourceLon: 13.405,
        sourceRadiusKm: 5.0,
        destLat: 48.1351,
        destLon: 11.5820,
        destRadiusKm: 5.0,
        requestedSeats: 2,
        rideStartTime: null,
        effectiveUserId: 'user-123',
      )),
    );

    return tripsAsync.when(
      data: (trips) => ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) => TripCard(trips[index]),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### 5️⃣ Booking Flow

```dart
// When user taps "Book Trip"
final notifier = ref.read(joinTripProvider.notifier);

final joinRequest = JoinTripRequest(
  tripId: trip.tripId,
  passengerId: userId,
  driverId: trip.driverId,
  pickupPoint: trip.sourceAddress,
  destinationPoint: trip.destinationAddress,
  rideStartTime: trip.tripStartDateTime,
  requestedSeats: 1,
);

// This triggers the API call
await notifier.joinTrip(joinRequest);

// Watch for response
final bookingResult = ref.watch(joinTripProvider);
bookingResult.when(
  data: (response) => showConfirmation(response),
  loading: () => showLoadingDialog(),
  error: (error, stack) => showErrorDialog(error),
);
```

## Data Flow

```
┌─────────────────────────┐
│      Passenger UI       │ (TripSearchExample, BookingConfirmationExample)
└────────────┬────────────┘
             │ ref.watch(provider)
             ▼
┌─────────────────────────┐
│  Riverpod Providers     │ (app_providers.dart, mutation_providers.dart)
└────────────┬────────────┘
             │ ref.read(repository)
             ▼
┌─────────────────────────┐
│     Repositories        │ (TripRepositoryImpl, BookingRepositoryImpl)
└────────────┬────────────┘
             │ apiService.method()
             ▼
┌─────────────────────────┐
│   API Services          │ (TripApiService, BookingApiService)
└────────────┬────────────┘
             │ dioClient.post/get()
             ▼
┌─────────────────────────┐
│    DioClient (HTTP)     │ (dio_client.dart)
│  + Auth Token Injection │
│  + Error Handling       │
└────────────┬────────────┘
             │ HTTP Request
             ▼
┌─────────────────────────┐
│   REST Backend          │ (http://34.30.27.79:8080)
└─────────────────────────┘
```

## All Available Endpoints

### Search Trips (Passenger)

```dart
// Find trips matching a complete route
ref.watch(searchMatchingRouteProvider((
  sourceLat: 52.52,
  sourceLon: 13.405,
  sourceRadiusKm: 5.0,
  destLat: 48.1351,
  destLon: 11.5820,
  destRadiusKm: 5.0,
  requestedSeats: 2,
  rideStartTime: '2024-01-15T10:00:00Z', // optional
  effectiveUserId: 'user-123',
)))
```

### Offer Trip (Driver)

```dart
final notifier = ref.read(offerTripProvider.notifier);
await notifier.offerTrip(OfferRideRequest(
  driverId: 'driver-123',
  vehicleNumber: 'ABC-1234',
  sourceAddress: Points(lat, lon, address),
  destinationAddress: Points(lat, lon, address),
  tripStartDateTime: '2024-01-15T10:00:00Z',
  offeredSeat: 4,
));
```

### Join Trip (Passenger)

```dart
final notifier = ref.read(joinTripProvider.notifier);
await notifier.joinTrip(JoinTripRequest(
  tripId: 'trip-123',
  passengerId: userId,
  driverId: driverId,
  pickupPoint: sourceLocation,
  destinationPoint: destLocation,
  rideStartTime: tripStartTime,
  requestedSeats: 2,
));
```

### View Upcoming Trips (Driver)

```dart
ref.watch(getUpcomingTripsForDriverProvider('driver-123'))
```

### View Upcoming Bookings (Passenger)

```dart
ref.watch(getUpcomingBookingsForPassengerProvider('user-123'))
```

### Cancel Trip (Driver)

```dart
final notifier = ref.read(cancelTripProvider.notifier);
await notifier.cancelTrip(CancelTripRequest(
  userId: 'driver-123',
  tripId: 'trip-123',
));
```

### Cancel Booking (Passenger)

```dart
final notifier = ref.read(cancelBookingProvider.notifier);
await notifier.cancelBooking(CancelTripRequest(
  userId: 'user-123',
  tripId: 'trip-123',
  rideId: 'ride-789',
));
```

## Model Examples

### Trip (Search Result)

```dart
Trip(
  tripId: 'trip-123',
  vehicleNumber: 'ABC-1234',
  driverId: 'driver-456',
  sourceAddress: Points(latitude: 52.52, longitude: 13.405),
  destinationAddress: Points(latitude: 48.1351, longitude: 11.5820),
  tripStartDateTime: '2024-01-15T10:00:00Z',
  offeredSeat: 4,
  currSeats: 2,
  tripStatus: 'active',
  pricePerKm: 5.0,
  routeDistance: 500.0,
)
```

### Points (Location)

```dart
Points(
  latitude: 52.52,
  longitude: 13.405,
  placeAddress: 'Berlin, Germany',
)
```

### PassengerRideResponse (Booking Confirmation)

```dart
PassengerRideResponse(
  rideId: 'ride-789',
  tripId: 'trip-123',
  driverId: 'driver-456',
  vehicleNumber: 'ABC-1234',
  rideStatus: 'confirmed',
  pickupLocation: Points(...),
  dropoffLocation: Points(...),
  bookedSeats: 2,
  estimatedFare: 50.0,
  tripStartDateTime: '2024-01-15T10:00:00Z',
)
```

## Error Handling

```dart
final result = ref.watch(provider);

if (result.hasError) {
  final error = result.error; // Exception
  
  // Show user-friendly message
  if (error is UnauthorizedException) {
    // User needs to login
    navigateToLogin();
  } else if (error is ServerException) {
    // Server error, show retry button
    showErrorDialog('Server error. Retry?');
  } else if (error is NetworkException) {
    // No internet
    showErrorDialog('Check your internet connection');
  }
}
```

## Testing Endpoints

Visit the **API Debug Screen** to test all endpoints without building full UI:

```dart
// Add to your routes
'/api-debug': (context) => ApiDebugScreen(),
```

Then navigate to `/api-debug` from your app to:
- Test each endpoint with sample data
- See request/response in real-time
- Check latency and status codes
- Debug errors

## Token Management

Tokens are stored securely and injected automatically:

```dart
// Save tokens after login
await ref.read(secureStorageProvider).saveTokens(
  accessToken: 'jwt-token',
  refreshToken: 'refresh-token',
  userId: 'user-123',
);

// Clear tokens on logout
await ref.read(secureStorageProvider).clearAll();

// Access token is automatically added to all requests:
// Authorization: Bearer <token>
```

## File Checklist

All these files have been created:

- ✅ `lib/core/network/dio_client.dart` - HTTP client
- ✅ `lib/core/network/api_exceptions.dart` - Exception types
- ✅ `lib/core/network/api_response.dart` - Response wrapper
- ✅ `lib/core/storage/secure_storage.dart` - Token storage
- ✅ `lib/core/providers/app_providers.dart` - Dependency injection
- ✅ `lib/core/providers/mutation_providers.dart` - Mutations
- ✅ `lib/core/pages/api_debug_screen.dart` - Testing tool
- ✅ `lib/features/trip/data/models/points.dart` - Location DTO
- ✅ `lib/features/trip/data/models/offer_ride_request.dart` - Request DTO
- ✅ `lib/features/trip/data/models/offer_ride_response.dart` - Response DTO
- ✅ `lib/features/trip/data/models/trip.dart` - Trip search result DTO
- ✅ `lib/features/booking/data/models/booking_requests.dart` - Booking request DTOs
- ✅ `lib/features/booking/data/models/booking_response.dart` - Booking response DTOs
- ✅ `lib/features/trip/data/services/trip_api_service.dart` - Trip API
- ✅ `lib/features/booking/data/services/booking_api_service.dart` - Booking API
- ✅ `lib/features/trip/domain/repositories/trip_repository.dart` - Repository interface
- ✅ `lib/features/trip/data/repositories/trip_repository_impl.dart` - Trip repository impl
- ✅ `lib/features/booking/data/repositories/booking_repository_impl.dart` - Booking impl
- ✅ `lib/features/trip/presentation/pages/trip_search_example.dart` - Passenger search UI
- ✅ `lib/features/trip/presentation/pages/driver_offer_trip_example.dart` - Driver offer UI
- ✅ `REST_BACKEND_INTEGRATION.md` - Complete guide
- ✅ `QUICKSTART_REST_INTEGRATION.md` - This file

## Next Steps

1. **Run build_runner**: `flutter pub run build_runner build`
2. **Wrap app with ProviderScope** in main.dart
3. **Try the API Debug Screen** at `/api-debug` route
4. **Copy example screens** into your app navigation
5. **Customize for your needs** (UI styling, additional fields, etc.)

## Common Issues & Fixes

### Build Runner Errors

```bash
# If you get conflicts during build_runner build:
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Import Errors

Make sure all imports are relative to your project:
```dart
import 'package:carsharing/core/network/dio_client.dart';
```

### Token Errors

Check secure storage has been initialized:
```dart
final storage = TokenStorage();
print(await storage.getAccessToken()); // Should print token
```

### Backend Connection

Test backend is running:
```bash
curl http://34.30.27.79:8080/v3/api-docs/trip
```

## Need Help?

- 📖 Full guide: `REST_BACKEND_INTEGRATION.md`
- 🧪 Test endpoints: Navigate to `/api-debug` screen
- 💬 Example code: See `*_example.dart` files in presentation layer
- 🔧 Debug logs: DioClient logs all requests/responses to console

---

**You're all set! Start building. 🚀**
