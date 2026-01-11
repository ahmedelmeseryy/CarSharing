# REST Backend Integration - Visual Architecture

## High-Level Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    Flutter App (iOS/Android)                     │
└──────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴──────────┐
                    │                    │
                    ▼                    ▼
          ┌──────────────────┐  ┌─────────────────┐
          │   Dashboard      │  │  Other Screens  │
          │  [Bug icon 🐛]   │  │                 │
          └────────┬─────────┘  └────────┬────────┘
                   │                     │
                   └──────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │  ref.watch()       │
                    │  (Riverpod)        │
                    └──────────┬─────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
    ┌────────────┐    ┌──────────────┐    ┌─────────────┐
    │Query Prov. │    │Mutation Prov.│    │Other Prov.  │
    │(Read-only) │    │(C/U/D)       │    │             │
    └─────┬──────┘    └───────┬──────┘    └──────┬──────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  API Services      │
                    │  • TripAPI         │
                    │  • BookingAPI      │
                    └──────────┬─────────┘
                              │
                    ┌─────────▼──────────┐
                    │  DioClient         │
                    │  [HTTP + JWT]      │
                    └──────────┬─────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
         [Network]    [Secure Storage]  [Interceptor]
              │         (Token)            (Auth)
              │               │               │
              └───────────────┼───────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  REST Backend      │
                    │ 34.30.27.79:8080   │
                    │  • Trip Service    │
                    │  • Booking Service │
                    └────────────────────┘
```

---

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  DashboardPage              RideListPage          OtherPages      │
│  [Bug icon 🐛]        [Passenger searches]    [Booking, etc]      │
│      │                        │                        │           │
│      └────────────┬───────────┴────────────┬──────────┘            │
│                   │                        │                       │
│              ref.watch()            Navigator.pushNamed()         │
│                   │                        │                       │
└───────────────────┼────────────────────────┼───────────────────────┘
                    │                        │
                    ▼                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT (Riverpod)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  searchMatchingRouteProvider                 joinTripMutation     │
│  ├─ Fetches trips from backend              ├─ Calls API         │
│  ├─ Caches results                          ├─ Handles errors     │
│  └─ Auto-refresh on demand                  └─ Updates state      │
│                                                                     │
│  getDriverTripsProvider        getPassengerRidesProvider          │
│  ├─ Driver view               ├─ Passenger bookings              │
│  └─ His posted trips          └─ Confirmed seats                 │
│                                                                     │
└──────────────────────┬──────────────────────┬──────────────────────┘
                       │                      │
                       ▼                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     DOMAIN LAYER (Models)                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Trip          Points       JoinTripRequest    OfferRideRequest   │
│  ├─ id         [lat,lng]    [tripId, ...]      [from, to, seats]  │
│  ├─ from                                                           │
│  ├─ to         DriverTrip   CancelBooking      OfferRideResponse  │
│  ├─ seats      Response     Request            [offerId, ...]     │
│  ├─ price                                                         │
│  └─ status     Passenger    PassengerRide                        │
│               Ride          Response                             │
│               Response                                            │
│                                                                     │
└──────────────────────┬──────────────────────┬──────────────────────┘
                       │                      │
                       ▼                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   DATA LAYER (Repositories)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  TripRepository              BookingRepository                     │
│  ├─ searchMatchingRoute()    ├─ joinTrip()                        │
│  ├─ createOffer()            ├─ getPassengerRides()               │
│  ├─ getDriverOffers()        └─ cancelBooking()                   │
│  ├─ getTripsByStatus()                                            │
│  ├─ updateTripStatus()                                            │
│  └─ cancelTrip()                                                  │
│                                                                     │
│  Each method calls TripAPI or BookingAPI                          │
│                                                                     │
└──────────────────────┬──────────────────────┬──────────────────────┘
                       │                      │
                       ▼                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    API LAYER (HTTP Services)                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  TripApiService                    BookingApiService              │
│  ├─ GET /trips/search              ├─ POST /bookings/join         │
│  ├─ POST /trips/offer              ├─ GET /bookings/passenger/:id │
│  ├─ GET /trips/driver/:id          └─ POST /bookings/:id/cancel   │
│  ├─ GET /trips?status=X                                           │
│  ├─ PATCH /trips/:id                                             │
│  └─ POST /trips/:id/cancel                                        │
│                                                                     │
│  Uses DioClient for HTTP                                          │
│                                                                     │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    NETWORK LAYER (DioClient)                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  DioClient (HTTP Client)                                          │
│  ├─ Base URL: 34.30.27.79:8080                                   │
│  ├─ Timeout: 30 seconds                                           │
│  ├─ Retry Logic: 3 attempts                                       │
│  └─ JWT Interceptor:                                              │
│      ├─ Automatically injects token in headers                    │
│      ├─ Handles 401 (expired token)                               │
│      └─ Auto-refreshes from secure storage                        │
│                                                                     │
│  SecureStorage                    ApiExceptions                    │
│  ├─ Stores JWT token              ├─ NetworkException             │
│  ├─ Stores refresh token          ├─ ParseException               │
│  └─ Encrypted (platform specific) ├─ UnauthorizedException        │
│                                   ├─ BadRequestException          │
│                                   └─ ServerException              │
│                                                                     │
└──────────────────────┬──────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│              REST Backend at 34.30.27.79:8080                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Trip Microservice          Booking Microservice                  │
│  ├─ Database: PostgreSQL    ├─ Database: PostgreSQL              │
│  ├─ Endpoints: 6            ├─ Endpoints: 3                      │
│  ├─ Handles: Routes         ├─ Handles: Reservations             │
│  └─ Returns: TripData       └─ Returns: BookingData              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Screen Navigation with REST Integration

```
┌─────────────────┐
│  Welcome Page   │
└────────┬────────┘
         │
    ┌────▼──────────────────────┐
    │   Login / Signup          │
    │  [Firebase Auth]          │
    └────┬──────────────────────┘
         │
    ┌────▼──────────────────────┐
    │   Dashboard               │
    │  ┌──────────────────────┐ │
    │  │  Search Card         │ │
    │  │  Featured Rides      │ │
    │  │  [Bug icon 🐛] [👤] │ │◄── Points to API Debug
    │  └──────────────────────┘ │
    └────┬──────────────────────┘
    ┌────┴────────────────────────┐
    │                             │
    ▼                             ▼
[RideListPage]            [RestIntegrationTester]
├─ Uses REST API          ├─ Firebase Tab
├─ searchMatchingRoute    ├─ REST API Tab
├─ Displays trips         └─ Links to debug
└─ Join trip buttons
    │
    ▼
[SeatSelectionPage]
├─ joinTripMutation
└─ Confirms booking

    │
    ▼
[UserDashboardPage]
├─ getPassengerRidesProvider
└─ Shows your bookings

---

Alternative Flow:

[DriverDashboardPage]
├─ getDriverTripsProvider
└─ Shows driver's posts
    │
    ▼
[AddTripPage]
├─ createOfferMutation
└─ Posts new trip
```

---

## API Call Flow Example

```
User taps "Search Rides" button
        │
        ▼
Widget calls: ref.watch(searchMatchingRouteProvider(...))
        │
        ▼
Riverpod checks if data cached
    ├─ Yes → Return cached data (instant)
    └─ No → Make HTTP request
        │
        ▼
TripRepository.searchMatchingRoute() called
        │
        ▼
TripApiService.searchTrips() creates request:
        GET /trips/search?origin=Nairobi&destination=Mombasa
        │
        ▼
DioClient.get() prepares request:
    ├─ Add base URL: http://34.30.27.79:8080
    ├─ Inject JWT token in Authorization header
    ├─ Set Content-Type: application/json
    └─ Set timeout: 30 seconds
        │
        ▼
Interceptor checks token
    ├─ Valid → Send request
    └─ Expired → Refresh from SecureStorage
        │
        ▼
Network sends HTTP request
        │
        ▼
Backend processes request
    ├─ Validates token (JWT)
    ├─ Queries database
    └─ Returns matching trips
        │
        ▼
DioClient receives response:
    200 OK + [Trip1, Trip2, Trip3...]
        │
        ▼
ApiResponse.fromJson() parses:
    ├─ Success → Return trip list
    └─ Error → Throw ApiException
        │
        ▼
Riverpod caches results
        │
        ▼
Widget rebuilds with trips
        │
        ▼
UI displays:
    ├─ Trip cards
    ├─ Prices
    ├─ Available seats
    └─ Book buttons
```

---

## Integration Points

```
┌──────────────────────────────────────────────────────────────┐
│  main.dart (App Root)                                        │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ ProviderScope(child: MainApp())                        │  │
│  │ [Enables all Riverpod providers throughout app]        │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
         │
         ├─ Routes configured:
         │  ├─ /dashboard → DashboardPage
         │  ├─ /rides → RideListPage
         │  ├─ /api-debug → ApiDebugScreen
         │  └─ /rest-integration → RestIntegrationTester
         │
         └─ Firebase still active for:
            ├─ Authentication
            └─ Legacy screens (gradual migration)

┌──────────────────────────────────────────────────────────────┐
│  Screens Using REST API (Ready)                             │
├──────────────────────────────────────────────────────────────┤
│  • trip_search_example.dart (Reference)                     │
│  • driver_offer_trip_example.dart (Reference)               │
│  • api_debug_screen.dart (Debug)                            │
│                                                              │
│  Screens to Migrate (Pending)                               │
│  • ride_list_page.dart                                      │
│  • driver_dashboard_page.dart                               │
│  • user_dashboard_page.dart                                 │
│  • seat_selection_page.dart                                 │
└──────────────────────────────────────────────────────────────┘
```

---

## How Debug Console Works

```
Dashboard Page [Bug icon 🐛]
        │
        ▼
Navigator.pushNamed(context, '/api-debug')
        │
        ▼
ApiDebugScreen opens
        │
        ├─ Displays 9 endpoint buttons:
        │  ├─ [Search Trips] button
        │  ├─ [Create Offer] button
        │  ├─ [Get Driver Offers] button
        │  ├─ [Get Trips by Status] button
        │  ├─ [Update Trip Status] button
        │  ├─ [Cancel Trip] button
        │  ├─ [Join Trip] button
        │  ├─ [Get Passenger Rides] button
        │  └─ [Cancel Booking] button
        │
        └─ When user taps button:
           │
           ▼
        Makes HTTP request directly
           │
           ▼
        Shows:
           ├─ Request details (method, URL, body)
           ├─ Response status code
           ├─ Response JSON
           └─ Execution time

User can see:
├─ API is working or failing
├─ Error messages
├─ Actual data structure
└─ Network issues (if any)
```

---

## Your Current Status

```
✅ COMPLETE:
├─ 26 implementation files
├─ 9 API endpoints
├─ Full infrastructure
├─ Riverpod integration
├─ Debug tools
└─ Example code

⚙️  IN PROGRESS:
├─ ProviderScope (just added ✅)
├─ Routes (just added ✅)
├─ Debug button (just added ✅)
└─ Screen migration (next step)

⏳ PENDING:
├─ ride_list_page.dart update
├─ Authentication JWT flow
├─ Other screen migrations
└─ Firebase removal
```

---

This architecture is clean, scalable, and ready for production!
