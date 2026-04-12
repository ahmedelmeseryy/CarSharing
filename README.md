# Kamili Drive — Car Sharing Mobile App

> ⚠️ **Educational Project - Under Development**  
> This project is created for educational purposes and is currently under active development. Features may be incomplete, and the application is not intended for production use.

A feature-rich car-sharing application built with Flutter, connecting drivers with passengers through a live REST API backend. The app provides role-based interfaces for passengers, drivers, and administrators.

---

## 🚀 Features

### Passenger
- **Trip Search:** Find trips by source and destination with radius-based proximity matching
- **Address Autocomplete:** Live address suggestions powered by Google Places API
- **Trip Details:** Route, date, price, available seats, and driver vehicle info
- **Booking:** Select seats and confirm — cash payment on trip
- **My Bookings:** View all active bookings with status tracking
- **Cancel Booking:** Cancel a seat; driver's available seats update automatically

### Driver
- **Registration:** Two-step sign-up — account creation followed by vehicle registration
- **Create Trip:** Set pickup/destination from autocomplete, date, time, seats, price per seat
- **My Trips:** View all active trips with booked seat count
- **Passenger List:** See who has booked each trip (name, contact, seats, status)
- **Cancel Trip:** Cancel a trip — all passenger bookings are updated automatically

### Admin
- **Overview:** Paginated list of all upcoming and historical trips with full details
- **Driver Approval:** Approve or reject pending driver registrations
- **User Management:** View all drivers and passengers; delete accounts

---

## 🛠️ Technical Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x / Dart |
| State Management | Riverpod (`FutureProvider.family`, `StateNotifierProvider`) |
| Networking | Dio HTTP Client with interceptor |
| Authentication | JWT — access + refresh token |
| Local Storage | `flutter_secure_storage` (encrypted) |
| Maps & Location | Google Places API (autocomplete), Haversine formula (proximity) |
| Serialization | `json_serializable` + `json_annotation` |
| Architecture | Clean Architecture (data / domain / presentation) |

### Key Packages
- `flutter_riverpod` — state management
- `dio` — HTTP client with interceptors
- `flutter_secure_storage` — encrypted token and profile storage
- `json_annotation` / `json_serializable` — type-safe JSON models
- `geolocator` — GPS location access
- `intl` — date and time formatting
- `email_validator` — email format validation

---

## 🏗️ Architecture

The app follows Clean Architecture with feature-based modules:

```
lib/
├── main.dart                         # App entry point, routing, LoginPage, SignUpPage
│
├── core/
│   ├── network/                      # DioClient — interceptors, error handling, token injection
│   ├── providers/                    # Riverpod providers (app_providers, mutation_providers)
│   └── storage/                      # SecureStorage — JWT + user profile
│
├── features/
│   ├── auth/
│   │   ├── data/services/            # AuthApiService — login, register, logout, password reset
│   │   └── presentation/             # ForgotPasswordPage, ChangePasswordPage
│   │
│   ├── trip/
│   │   ├── data/                     # TripApiService, models (Trip, OfferRide*), repository impl
│   │   ├── domain/                   # ITripRepository interface
│   │   └── presentation/             # AddTripPage (driver creates a trip)
│   │
│   ├── booking/
│   │   ├── data/                     # BookingApiService, models (BookingRequest/Response), repository impl
│   │   └── presentation/             # BookingConfirmationPage, TripBookingDetailPage
│   │
│   ├── driver/
│   │   └── presentation/             # DriverDashboardPage, DriverTripDetailsPage,
│   │       └── tabs/                 # RegisterVehiclePage, DriverWelcomeTab
│   │
│   ├── passenger/
│   │   └── presentation/             # UserDashboardPage, TripSearchPage, TripSearchResultsPage,
│   │       └── tabs/                 # TripDetailsPage, PaymentMethodPage, WelcomeTab, AvailableTripsTab
│   │
│   ├── admin/
│   │   └── presentation/             # AdminDashboardPage, SeedTripsPage
│   │
│   ├── profile/
│   │   └── presentation/             # ProfilePage — view/edit profile, vehicle list, logout
│   │
│   └── user/
│       └── data/services/            # UserApiService — vehicle registration and lookup
│
└── shared/
    ├── widgets/                      # AddressAutocompleteField, MapLocationPicker, TripCard
    ├── services/                     # LocationService, PlacesService, TripSearchService
    ├── models/                       # Shared models (TripStop)
    ├── constants/                    # GermanCities list
    └── utils/                        # SeedTestTrips (dev utility)
```

---

## 🌐 Backend API

The app connects to a microservice REST backend:

| Service | Base Path | Responsibility |
|---|---|---|
| auth-service | `/auth-service/api/` | Register, login, logout, password |
| trip-service | `/trip-service/api/` | Trips, bookings, search |
| user-service | `/user-service/api/` | User profiles, vehicles |

### Key Endpoints Used

| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth-service/api/auth/register` | Register new user |
| POST | `/auth-service/api/auth/login` | Login |
| POST | `/trip-service/api/trips/offer` | Driver creates a trip |
| POST | `/trip-service/api/trips/cancel` | Driver cancels a trip |
| GET | `/trip-service/api/trips/active/driver/{id}` | Driver's active trips |
| GET | `/trip-service/api/trips/search/matching-route` | Search trips by route |
| POST | `/trip-service/api/rides/book` | Passenger books a trip |
| POST | `/trip-service/api/rides/cancel` | Passenger cancels a booking |
| GET | `/trip-service/api/rides/active/passenger/{id}` | Passenger's active bookings |
| GET | `/user-service/api/vehicles/{userId}` | Driver's registered vehicles |
| POST | `/user-service/api/vehicles/register` | Register a vehicle |

---

## 📋 Prerequisites

- **Flutter SDK** 3.0 or higher — [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git**
- A running instance of the backend (trip-service, user-service, auth-service)

---

## 🔧 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/ahmedelmeseryy/CarSharing.git
cd CarSharing
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure the Backend URL

Open `lib/core/network/dio_client.dart` and update the base URL:

```dart
static const String baseUrl = 'http://your-backend-ip';
```

**Common values:**
- Android Emulator: `http://10.0.2.2:8080`
- iOS Simulator: `http://localhost:8080`
- Physical device: `http://192.168.x.x:8080`
- Deployed backend: `http://your-server-ip`

### 4. Run the App
```bash
flutter run
```

---

## 📱 Usage Guide

### As a Passenger
1. Register with role **User**
2. From Home, tap **Search for Trips**
3. Enter pickup and destination — select from autocomplete suggestions
4. Browse results, tap a trip to view details
5. Tap **Book** and confirm seats
6. View bookings in the **Booked** tab
7. Cancel a booking from the booking card if needed

### As a Driver
1. Register with role **Driver** and complete vehicle registration
2. Wait for **admin approval** (you will not be able to create trips until approved)
3. From Home, tap **Create Trip**
4. Set start point, destination, date, time, seats, and price
5. View your trips in the **My Trips** tab
6. Tap a trip to see the passenger list
7. Cancel a trip if needed — all passengers are notified

### As an Admin
1. Log in with an admin account
2. **Overview tab:** Monitor all trips
3. **Users tab:** Approve/reject drivers, delete accounts


---

## 🔄 Changelog

### v2.2.0 — Current
- ✅ Full project restructure: feature-based Clean Architecture with `features/<name>/presentation` layers
- ✅ Shared code moved to `shared/widgets`, `shared/services`, `shared/utils`, `shared/models`, `shared/constants`
- ✅ All imports updated to reflect new package paths — no broken references
- ✅ `ProfilePage` extracted from `main.dart` into `features/profile/presentation/profile_page.dart`
- ✅ Admin cascade delete: cancels all user trips/bookings before deleting an account

### v2.1.0
- ✅ Cancelled bookings hidden from passenger's booking list
- ✅ Cancelled passengers filtered from driver's passenger list
- ✅ Fixed trip creation: `vehicleNumber` now sent in request; vehicle dropdown shows correct names
- ✅ Fixed "Failed to create trip" false error — success now detected via `tripId` presence
- ✅ Fixed My Trips infinite loading — 401 interceptor no longer wipes `user_id` from storage
- ✅ Removed all debug print statements
- ✅ Cleaned up unused files and outdated documentation

### v2.0.0
- ✅ Fully migrated from Firebase to REST API backend
- ✅ JWT authentication replacing Firebase Auth
- ✅ Admin dashboard with trip overview and user management
- ✅ Driver trip details page with passenger info
- ✅ Haversine fallback search when `/matching-route` endpoint is unavailable
- ✅ Custom `DateTimeConverter` — backend-compatible ISO format without milliseconds
- ✅ Local booking cache — newly created bookings appear instantly

---

## 🐛 Troubleshooting

**App won't build:**
```bash
flutter clean
flutter pub get
flutter run
```

**Android build errors:**
```bash
cd android && ./gradlew clean && cd ..
flutter clean && flutter pub get
```

**iOS build errors:**
```bash
cd ios && pod deinstall && pod install && cd ..
flutter clean && flutter pub get
```

**Backend connection issues:**
- Confirm the base URL in `dio_client.dart` is correct
- For Android emulator use `10.0.2.2` not `localhost`
- Check that all three services (auth, trip, user) are running

**Maps / autocomplete not working:**
- Check internet connection
- Verify the Google Places API key is configured

**Search returns no results:**
- The primary `/matching-route` endpoint may be unavailable — the app automatically falls back to a two-stage client-side search
- Try widening the radius values

**Models changed and app won't compile:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📝 Development Notes

### Adding new JSON models
After modifying any `@JsonSerializable` model, regenerate the `.g.dart` files:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Running tests
```bash
flutter test
```

---

## 📄 Academic Project

Developed under the supervision of the Computer Science Department at Philipps-Universität Marburg, Germany.

- **Institution:** Philipps-Universität Marburg
- **Department:** Computer Science (Fachbereich Mathematik und Informatik)
- **Purpose:** Educational and research purposes

All rights reserved. This project is for academic use and demonstration purposes only.

---

## 👥 Authors

- Ahmed Elmesery — [GitHub](https://github.com/ahmedelmeseryy)
- Sumeet Kumar — [GitHub](https://github.com/iamsumitk)

---

## 🙏 Acknowledgments

- OpenStreetMap for map tiles
- Google Places for address autocomplete
- Flutter team for the framework
- All contributors

---

## ⚠️ Important Notice

**This is an educational project currently under active development.**

- **Purpose:** Created for learning and demonstration purposes
- **Status:** Work in progress — features may be incomplete or subject to change
- **Not Production Ready:** Not intended for commercial or production use
- **API Compliance:** Ensure compliance with OpenStreetMap's [Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/) if using map tiles
