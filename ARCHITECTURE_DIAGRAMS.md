# Architecture Diagrams & Visual Guides

## 1. Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP (Your Device)                   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    PRESENTATION LAYER (UI)                   │  │
│  │                                                               │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │  │
│  │  │    Search   │  │     Offer    │  │  Debug Console     │  │  │
│  │  │    Screen   │  │  Trip Screen │  │  (API Testing)     │  │  │
│  │  └─────────────┘  └──────────────┘  └────────────────────┘  │  │
│  │       │                 │                      │              │  │
│  │       └─────────┬───────┴──────────────────────┘              │  │
│  │               │                                               │  │
│  └───────────────┼───────────────────────────────────────────────┘  │
│                  │                                                   │
│  ┌───────────────▼───────────────────────────────────────────────┐  │
│  │            STATE MANAGEMENT LAYER (Riverpod)                  │  │
│  │                                                               │  │
│  │  Providers:                                                   │  │
│  │  • searchMatchingRouteProvider(params)                        │  │
│  │  • joinTripProvider (mutation)                                │  │
│  │  • offerTripProvider (mutation)                               │  │
│  │  • getUpcomingTripsForDriverProvider(driverId)                │  │
│  │  • etc.                                                       │  │
│  │                                                               │  │
│  │  Dependencies:                                                │  │
│  │  ├─ tripRepositoryProvider                                    │  │
│  │  └─ bookingRepositoryProvider                                 │  │
│  │                                                               │  │
│  └───────────────┬───────────────────────────────────────────────┘  │
│                  │                                                   │
│  ┌───────────────▼───────────────────────────────────────────────┐  │
│  │          DOMAIN LAYER (Business Logic - Interfaces)           │  │
│  │                                                               │  │
│  │  ITripRepository (abstract)                                   │  │
│  │  ├─ searchMatchingRoute()                                     │  │
│  │  ├─ offerTrip()                                               │  │
│  │  └─ cancelTrip()                                              │  │
│  │                                                               │  │
│  │  IBookingRepository (abstract)                                │  │
│  │  ├─ joinTrip()                                                │  │
│  │  └─ cancelBooking()                                           │  │
│  │                                                               │  │
│  └───────────────┬───────────────────────────────────────────────┘  │
│                  │                                                   │
│  ┌───────────────▼───────────────────────────────────────────────┐  │
│  │        DATA LAYER (Implementation + HTTP)                      │  │
│  │                                                               │  │
│  │  Repositories:                                                │  │
│  │  ├─ TripRepositoryImpl                                         │  │
│  │  └─ BookingRepositoryImpl                                      │  │
│  │                                                               │  │
│  │  API Services:                                                │  │
│  │  ├─ TripApiService (6 endpoints)                              │  │
│  │  └─ BookingApiService (3 endpoints)                           │  │
│  │                                                               │  │
│  │  Data Models (DTOs):                                          │  │
│  │  ├─ Points, Trip, OfferRideRequest/Response                  │  │
│  │  ├─ JoinTripRequest, CancelTripRequest                        │  │
│  │  └─ DriverTripResponse, PassengerRideResponse                 │  │
│  │                                                               │  │
│  └───────────────┬───────────────────────────────────────────────┘  │
│                  │                                                   │
│  ┌───────────────▼───────────────────────────────────────────────┐  │
│  │      INFRASTRUCTURE LAYER (HTTP + Auth + Storage)             │  │
│  │                                                               │  │
│  │  ┌──────────────────┐     ┌─────────────────┐  ┌──────────┐  │  │
│  │  │   DioClient      │     │  TokenStorage   │  │ApiExcept │  │  │
│  │  │                  │     │  (SecureStorage)│  │ ion      │  │  │
│  │  │ • HTTP methods   │────→│  • Save tokens  │  │Hierarchy │  │  │
│  │  │ • JWT injection  │     │  • Load tokens  │  │ • 401    │  │  │
│  │  │ • Interceptors   │     │  • Clear all    │  │ • 404    │  │  │
│  │  │ • Logging        │     │  • hasToken()   │  │ • 5xx    │  │  │
│  │  │ • Error mapping  │     └─────────────────┘  └──────────┘  │  │
│  │  └──────────────────┘                                         │  │
│  │                                                               │  │
│  │  ApiResponse<T> Wrapper                                       │  │
│  │  ├─ data: T?                                                  │  │
│  │  ├─ error: ApiError?                                          │  │
│  │  ├─ message: String?                                          │  │
│  │  └─ timestamp: String?                                        │  │
│  │                                                               │  │
│  └───────────────┬───────────────────────────────────────────────┘  │
│                  │                                                   │
│                  │ HTTPS Requests with JWT Bearer Token             │
│                  │ Authorization: Bearer <access_token>             │
│                  │                                                   │
└──────────────────┼───────────────────────────────────────────────────┘
                   │
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│              REST BACKEND (http://34.30.27.79:8080)                 │
│                                                                      │
│  ┌────────────────────────────────────┐                             │
│  │    Trip Service Controller          │                            │
│  │                                    │                            │
│  │  POST   /api/trips/offer          │                            │
│  │  POST   /api/trips/cancel         │                            │
│  │  GET    /api/trips/upcoming/driver/{driverId}                  │
│  │  GET    /api/trips/search/near-source                          │
│  │  GET    /api/trips/search/near-destination                     │
│  │  GET    /api/trips/search/matching-route                       │
│  │                                    │                            │
│  └────────────────────────────────────┘                             │
│                                                                      │
│  ┌────────────────────────────────────┐                             │
│  │   Booking Service Controller        │                            │
│  │                                    │                            │
│  │  POST   /api/bookings/join         │                            │
│  │  POST   /api/bookings/cancel       │                            │
│  │  GET    /api/bookings/upcoming/passenger/{passengerId}          │
│  │                                    │                            │
│  └────────────────────────────────────┘                             │
│                                                                      │
│  Microservices:                                                     │
│  ├─ Trip Service (MySQL)                                            │
│  ├─ Booking Service (MySQL)                                         │
│  ├─ Auth Service (JWT validation)                                   │
│  └─ Routing/Map Service (Google Maps API)                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Data Flow: Search & Book Workflow

```
USER ACTION: Passenger searches for trips from Berlin to Munich

1. UI Input Collection
   ┌──────────────────────────────────┐
   │ TripSearchExample                │
   │ • User enters: Source & Dest     │
   │ • Taps: "Search"                 │
   │ • Coordinates collected:         │
   │   source: (52.52, 13.405)        │
   │   dest: (48.1351, 11.5820)       │
   │   radius: 5km                    │
   └──────────────────────────────────┘
                │
                ▼
2. Provider Invocation (Riverpod)
   ┌──────────────────────────────────────────────────┐
   │ ref.watch(searchMatchingRouteProvider((         │
   │   sourceLat: 52.52,                             │
   │   sourceLon: 13.405,                            │
   │   sourceRadiusKm: 5,                            │
   │   destLat: 48.1351,                             │
   │   destLon: 11.5820,                             │
   │   destRadiusKm: 5,                              │
   │   requestedSeats: 2,                            │
   │   effectiveUserId: 'user-123',                  │
   │ )))                                             │
   └──────────────────────────────────────────────────┘
                │
                ▼
3. Repository Call
   ┌──────────────────────────────────┐
   │ TripRepositoryImpl               │
   │ .searchMatchingRoute(...)        │
   └──────────────────────────────────┘
                │
                ▼
4. API Service Call
   ┌──────────────────────────────────────────────────┐
   │ TripApiService.searchMatchingRoute(...)         │
   │ Builds query params:                            │
   │  ?sourceLat=52.52&sourceLon=13.405              │
   │  &sourceRadiusKm=5&destLat=48.1351              │
   │  &destLon=11.5820&destRadiusKm=5                │
   │  &requestedSeats=2&effectiveUserId=user-123     │
   └──────────────────────────────────────────────────┘
                │
                ▼
5. HTTP Request (DioClient)
   ┌──────────────────────────────────────────────────┐
   │ GET /api/trips/search/matching-route             │
   │ Headers:                                         │
   │  Authorization: Bearer eyJhbGc...               │
   │  Content-Type: application/json                  │
   │ Timeout: 30s                                     │
   │ (Token from TokenStorage, injected by DioClient) │
   └──────────────────────────────────────────────────┘
                │
          Network Layer
                │
                ▼
6. Backend Processing
   ┌──────────────────────────────────────────────────┐
   │ Spring Boot REST API                             │
   │ TripController.searchMatchingRoute()             │
   │ ✓ Validates JWT token                           │
   │ ✓ Parses query parameters                       │
   │ ✓ Queries database for matching trips           │
   │ ✓ Filters by location + time + seats            │
   │ ✓ Calculates route geometry                     │
   │ ✓ Returns up to 50 matching trips               │
   └──────────────────────────────────────────────────┘
                │
                ▼
7. HTTP Response (200 OK)
   ┌──────────────────────────────────────────────────┐
   │ Content-Type: application/json                   │
   │                                                  │
   │ {                                                │
   │   "data": [                                      │
   │     {                                            │
   │       "tripId": "trip-123",                      │
   │       "vehicleNumber": "ABC-1234",               │
   │       "driverId": "driver-456",                  │
   │       "sourceAddress": {                         │
   │         "latitude": 52.5165,                     │
   │         "longitude": 13.3880,                    │
   │         "placeAddress": "Berlin Central"         │
   │       },                                         │
   │       "destinationAddress": {                    │
   │         "latitude": 48.1372,                     │
   │         "longitude": 11.5809,                    │
   │         "placeAddress": "Munich City"            │
   │       },                                         │
   │       "tripStartDateTime": "2024-01-15T10:00:00Z",│
   │       "offeredSeat": 4,                          │
   │       "currSeats": 2,                            │
   │       "tripStatus": "active",                    │
   │       "pricePerKm": 5.0,                         │
   │       "routeDistance": 500.0,                    │
   │       "joinedRidersId": ["user-111", "user-222"]│
   │     },                                           │
   │     { ... more trips ... }                       │
   │   ],                                             │
   │   "error": null,                                 │
   │   "message": "Success",                          │
   │   "timestamp": "2024-01-15T10:12:34Z"            │
   │ }                                                │
   └──────────────────────────────────────────────────┘
                │
                ▼
8. Deserialization (DioClient)
   ┌──────────────────────────────────────────────────┐
   │ JSON → ApiResponse<List<Trip>>                   │
   │ ✓ Parse JSON with json_serializable              │
   │ ✓ Create Trip objects from JSON                  │
   │ ✓ Map ApiResponse wrapper                        │
   │ ✓ Check isSuccess (data != null && error == null)│
   └──────────────────────────────────────────────────┘
                │
                ▼
9. Repository Unwrapping
   ┌──────────────────────────────────────────────────┐
   │ TripRepositoryImpl.searchMatchingRoute()          │
   │ if (response.isSuccess && response.data != null) │
   │   return response.data!  // List<Trip>          │
   │ else                                             │
   │   throw Exception(response.errorMessage)        │
   └──────────────────────────────────────────────────┘
                │
                ▼
10. Riverpod State Update
   ┌──────────────────────────────────────────────────┐
   │ searchMatchingRouteProvider:                      │
   │ AsyncValue: loading → success                    │
   │ data = List<Trip> with 5 results                 │
   │                                                  │
   │ Notifies all listeners:                          │
   │ • TripSearchExample rebuilds                     │
   │ • Shows ListView with results                    │
   └──────────────────────────────────────────────────┘
                │
                ▼
11. UI Rendering
   ┌──────────────────────────────────────────────────┐
   │ CircularProgressIndicator disappears             │
   │ ListView appears with 5 trip cards:              │
   │ ┌────────────────────────────────┐               │
   │ │ Berlin → Munich                │               │
   │ │ 🕒 2024-01-15 10:00 AM         │               │
   │ │ 🚗 ABC-1234                    │               │
   │ │ 👤 Driver-456                  │               │
   │ │ 💵 ₹2500 • 2 seats available   │               │
   │ │ [TAP TO BOOK]                  │               │
   │ └────────────────────────────────┘               │
   │                                                  │
   │ [More trip cards...]                             │
   └──────────────────────────────────────────────────┘
                │
                ▼
12. User Taps "Book Trip"
   ┌──────────────────────────────────────────────────┐
   │ Navigates to BookingConfirmationExample          │
   │ Shows trip details                               │
   │ User taps "Confirm Booking"                      │
   └──────────────────────────────────────────────────┘
                │
                ▼
13. Booking Submission (JoinTrip)
   ┌──────────────────────────────────────────────────┐
   │ ref.read(joinTripProvider.notifier)              │
   │ .joinTrip(JoinTripRequest(                       │
   │   tripId: 'trip-123',                            │
   │   passengerId: 'user-123',                       │
   │   driverId: 'driver-456',                        │
   │   pickupPoint: sourceAddress,                    │
   │   destinationPoint: destAddress,                 │
   │   rideStartTime: '2024-01-15T10:00:00Z',         │
   │   requestedSeats: 2,                             │
   │ ))                                               │
   └──────────────────────────────────────────────────┘
                │
                ▼
14. Similar flow as search:
    UI → Riverpod → Repository → Service → DioClient
    → Backend → Response → Deserialization → UI Update
                │
                ▼
15. Success: Booking Confirmation
   ┌──────────────────────────────────────────────────┐
   │ PassengerRideResponse received:                   │
   │ {                                                │
   │   "rideId": "ride-789",                          │
   │   "tripId": "trip-123",                          │
   │   "rideStatus": "confirmed",                     │
   │   "estimatedFare": 2500,                         │
   │   ...                                            │
   │ }                                                │
   │                                                  │
   │ UI shows:                                        │
   │ ✓ Booking Confirmed!                             │
   │   Ride Status: Confirmed                         │
   │   [Back to Search]                               │
   └──────────────────────────────────────────────────┘
```

---

## 3. State Management Flow (Riverpod)

```
┌─────────────────────────────────────────────────────────┐
│        QUERY PROVIDER (Read Data - FutureProvider)      │
└─────────────────────────────────────────────────────────┘

    Initial State
         │
         ▼
    AsyncValue.data(null)  [Initial]
         │
         ▼
    ref.watch(provider)    [Request triggered]
         │
         ▼
    AsyncValue.loading()   [Fetching...]
         │
         ▼
         ├─→ ✓ Success    → AsyncValue.data(trips)
         │
         └─→ ✗ Error      → AsyncValue.error(exception)

    UI handles with .when():
    ┌──────────────────────────────────────────────┐
    │ trips.when(                                  │
    │   data: (value) {                            │
    │     return ListView(                         │
    │       itemCount: value.length,               │
    │       itemBuilder: (i) => TripCard(value[i])│
    │     );                                       │
    │   },                                         │
    │   loading: () => CircularProgressIndicator(),│
    │   error: (error, stack) => ErrorWidget(),   │
    │ )                                            │
    └──────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────┐
│   MUTATION PROVIDER (Write Data - StateNotifier)        │
└─────────────────────────────────────────────────────────┘

    Initial State
         │
         ▼
    AsyncValue.data(null)  [Idle]
         │
         ▼
    notifier.joinTrip(request)  [Action triggered]
         │
         ▼
    AsyncValue.loading()   [Processing...]
         │
         ▼
         ├─→ ✓ Success    → AsyncValue.data(response)
         │   Booking confirmed!
         │   User can see booking details
         │
         └─→ ✗ Error      → AsyncValue.error(exception)
             Show retry button

    UI follows same .when() pattern
```

---

## 4. File Dependency Graph

```
main.dart
  └─ ProviderScope
       └─ app.dart

lib/features/trip/presentation/pages/
  ├─ trip_search_example.dart
  │  ├─ imports: flutter_riverpod
  │  ├─ imports: searchMatchingRouteProvider
  │  ├─ imports: joinTripProvider
  │  └─ uses: Trip, Points, JoinTripRequest
  │
  └─ driver_offer_trip_example.dart
     ├─ imports: offerTripProvider
     ├─ imports: getUpcomingTripsForDriverProvider
     └─ uses: OfferRideRequest, OfferRideResponse

lib/core/providers/
  ├─ app_providers.dart
  │  ├─ depends on: DioClient, TokenStorage
  │  ├─ depends on: TripApiService, BookingApiService
  │  ├─ depends on: TripRepositoryImpl, BookingRepositoryImpl
  │  └─ provides: All query providers
  │
  └─ mutation_providers.dart
     ├─ depends on: tripRepositoryProvider, bookingRepositoryProvider
     ├─ provides: offerTripProvider, joinTripProvider, etc.
     └─ uses: StateNotifier<AsyncValue<T>>

lib/features/trip/data/repositories/
  └─ trip_repository_impl.dart
     ├─ depends on: TripApiService
     ├─ implements: ITripRepository
     └─ returns: Trip, OfferRideResponse, DriverTripResponse

lib/features/booking/data/repositories/
  └─ booking_repository_impl.dart
     ├─ depends on: BookingApiService
     ├─ implements: IBookingRepository
     └─ returns: PassengerRideResponse

lib/features/trip/data/services/
  └─ trip_api_service.dart
     ├─ depends on: DioClient
     ├─ calls: GET/POST endpoints
     └─ returns: ApiResponse<T>

lib/features/booking/data/services/
  └─ booking_api_service.dart
     ├─ depends on: DioClient
     ├─ calls: GET/POST endpoints
     └─ returns: ApiResponse<T>

lib/core/network/
  ├─ dio_client.dart
  │  ├─ depends on: TokenStorage
  │  ├─ has: RequestInterceptor, ErrorInterceptor
  │  └─ returns: Generic HTTP methods (get<T>, post<T>, etc.)
  │
  └─ api_exceptions.dart
     ├─ custom exceptions for different HTTP codes
     └─ used by: DioClient error mapping

lib/core/storage/
  └─ secure_storage.dart
     └─ used by: DioClient (token injection)

lib/features/trip/data/models/
  ├─ points.dart
  ├─ trip.dart
  ├─ offer_ride_request.dart
  └─ offer_ride_response.dart

lib/features/booking/data/models/
  ├─ booking_requests.dart (JoinTripRequest, CancelTripRequest)
  └─ booking_response.dart (DriverTripResponse, PassengerRideResponse)
```

---

## 5. Provider Lifecycle

```
┌──────────────────────────────────────────────────┐
│         Provider Creation & Lifecycle             │
└──────────────────────────────────────────────────┘

1. App starts
   └─ ProviderScope wraps the app
   └─ All providers initialized (lazy)

2. Widget calls ref.watch(provider)
   ├─ If provider not yet created:
   │  └─ Provider function executes
   │  └─ Dependencies resolved
   │  └─ Initial state set
   │
   └─ If already created:
      └─ Returns cached instance
      └─ Subscribes to updates

3. Provider data changes
   └─ All watchers notified
   └─ Dependent providers invalidated
   └─ UI rebuilds with new data

4. Widget unmounts
   └─ If provider is .autoDispose:
      └─ Provider cleaned up after 0.3s of no watchers
      └─ Memory freed

Example: searchMatchingRouteProvider
    ┌──────────────────────────────────┐
    │ Initial: Not created             │
    └──────────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────┐
    │ First watch:                     │
    │ ref.watch(searchMatchingRoute...) │
    └──────────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────┐
    │ Provider executes:               │
    │ repository.searchMatchingRoute()  │
    │ Returns: FutureProvider → loading │
    └──────────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────┐
    │ API call completes               │
    │ Returns: List<Trip>              │
    └──────────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────┐
    │ All watchers notified            │
    │ UI rebuilds with trips list      │
    └──────────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────┐
    │ User navigates away              │
    │ Widget unmounts                  │
    │ .autoDispose waits 0.3s          │
    └──────────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────┐
    │ If no more watchers:             │
    │ Provider cleaned up              │
    │ Memory freed                     │
    └──────────────────────────────────┘
```

---

## 6. Error Handling Flow

```
                API Request
                     │
                     ▼
        ┌────────────────────────┐
        │  DioClient.post(...)   │
        └────────────────────────┘
                     │
       ┌─────────────┼─────────────┐
       │             │             │
       ▼             ▼             ▼
    2xx OK        4xx Error      5xx Error / Network
       │             │             │
       ▼             ▼             ▼
    JSON Parse   HTTP Error    Connection Error
       │             │             │
       ├─→ Success   │             │
       │ AsyncValue. │             │
       │ data(T)     │             │
       │             ▼             │
       │        Map to Custom      │
       │        Exception:         │
       │        ├─→ 401 →          │
       │        │  Unauthorized    │
       │        ├─→ 403 →          │
       │        │  Forbidden       │
       │        ├─→ 404 →          │
       │        │  NotFound        │
       │        ├─→ 5xx →          │
       │        │  Server          │
       │        │                  │
       │        └─→ Other →        │
       │           Network        │
       │             │             │
       │             └─────────────┤
       │                           │
       └───────────────┬───────────┘
                       ▼
            ┌─────────────────────────────┐
            │ Repository.method() catches │
            │ and re-throws (if needed)   │
            └─────────────────────────────┘
                       │
                       ▼
            ┌─────────────────────────────┐
            │ AsyncValue.error(exception) │
            │ Propagates to UI            │
            └─────────────────────────────┘
                       │
                       ▼
            ┌─────────────────────────────┐
            │ UI .when():                 │
            │ error: (error, stack) =>    │
            │   showErrorDialog(error)    │
            └─────────────────────────────┘
```

---

This visual guide should help you understand how all the pieces fit together!
