# Car Sharing Mobile App

> ⚠️ **Educational Project - Under Development**  
> This project is created for educational purposes and is currently under active development. Features may be incomplete, and the application is not intended for production use.

A feature-rich car-sharing application built with Flutter, designed to connect drivers with passengers. The app provides a seamless experience for both creating and booking trips, with dedicated interfaces for user and driver roles.

## 🚀 Key Features

### For Users (Passengers)
- **Welcome Screen:** Clean landing page with quick access to trip search
- **Trip Search:** Find available trips by searching for destinations with autocomplete suggestions
- **Address Autocomplete:** Real-time address suggestions powered by OpenStreetMap Nominatim with:
    - Debounced input (300ms) to reduce server load
    - Fallback suggestions for common cities when network is unavailable
    - Resilient network handling with timeout, retries, and exponential backoff
- **Trip Details:** View comprehensive trip information including route, date, price, available seats, and driver details
- **Booking System:**
    - Select number of seats
    - Secure payment processing
    - Booking confirmation
- **My Bookings:** View and manage all booked trips with status tracking
- **Trip Cancellation:** Cancel bookings with automatic refunds

### For Drivers
- **Welcome Screen:** Driver-focused landing page with quick trip creation
- **Trip Creation:** Add new trips with comprehensive details:
    - Starting point and destination (with map integration)
    - Date and time selection
    - Available seats and pricing
    - Vehicle information
- **My Created Trips:** View and manage all created trips
- **Trip Details with Passenger Info:** 
    - See who booked your trips
    - View passenger contact information
    - Track bookings and seat availability
- **Booking Management:** Monitor trip bookings in real-time
- **Trip Templates:** Save and reuse common routes

## 🛠️ Technical Stack

- **Frontend:** Flutter 3.x
- **Backend:** REST API Integration
- **State Management:** Riverpod
- **Authentication:** Firebase Authentication + REST API
- **Database:** Backend REST API (replacing Firebase Firestore)
- **Maps & Location:**
    - OpenStreetMap (flutter_map) for map visualization
    - OpenStreetMap Nominatim for address autocomplete
    - Geolocator for GPS tracking

### Key Packages
- `flutter_riverpod`: State management
- `dio`: HTTP client for REST API calls
- `firebase_auth`: User authentication
- `firebase_core`: Firebase initialization
- `flutter_map`: OpenStreetMap integration
- `geolocator`: GPS location access
- `intl`: Date and time formatting
- `json_annotation`: JSON serialization
- `flutter_secure_storage`: Secure token storage
- `http`: HTTP requests for geocoding
- `latlong2`: Latitude/longitude handling

## 📋 Prerequisites

- **Flutter SDK** (3.0 or higher) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git**

### Backend Requirements
The app connects to a REST API backend with the following endpoints:
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/trips/search` - Search for trips
- `POST /api/trips` - Create a trip
- `GET /api/trips/upcoming/driver/{driverId}` - Get driver's trips
- `POST /api/bookings` - Create a booking
- `GET /api/bookings/upcoming/passenger/{passengerId}` - Get passenger bookings
- `PUT /api/bookings/cancel` - Cancel a booking

## 🔧 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/ahmedelmeseryy/CarSharing.git
cd CarSharing
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Configure Backend API URL

The app needs to connect to your backend server. Update the API base URL:

1. Open `lib/core/network/dio_client.dart`
2. Update the `baseUrl` to point to your backend:
```dart
static const String baseUrl = 'http://your-backend-api.com';
```

**For local development:**
- **Android Emulator:** Use `http://10.0.2.2:8080`
- **iOS Simulator:** Use `http://localhost:8080`
- **Physical Device:** Use your machine's IP address (e.g., `http://192.168.1.100:8080`)

### 4. Firebase Configuration (Already Set Up)

The project already includes Firebase configuration files:
- `android/app/google-services.json` (Android)
- `ios/Runner/GoogleService-Info.plist` (iOS)

**Note:** If you want to use your own Firebase project:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create/select a project
3. Enable **Authentication** with Email/Password
4. Download and replace the configuration files

### 5. Run the App

```bash
flutter run
```

That's it! The app should launch on your connected device or emulator.

## 🚀 Building for Release

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 📱 Usage Guide

### First Time Setup
1. **Launch the app**
2. **Register** a new account or **Login** with existing credentials
3. **Choose your role:**
   - Select "User" for booking trips
   - Select "Driver" for offering trips

### As a Passenger
1. From the **Home** screen, tap **"Search for Trips"**
2. Enter your pickup and destination locations
3. Browse available trips
4. Tap on a trip to view details
5. Book by selecting seats and payment method
6. View your bookings in the **"Booked"** tab
7. Cancel bookings if needed

### As a Driver
1. From the **Home** screen, tap **"Create Trip"**
2. Fill in trip details:
   - Select pickup and drop-off locations on the map
   - Set date and time
   - Enter vehicle details
   - Set trip price and available seats
3. View your created trips in the **"My Trips"** tab
4. Tap on a trip to see passenger bookings
5. Monitor bookings and earnings

## 📁 Project Structure

```
lib/
├── core/                           # Core functionality
│   ├── network/                    # Network layer (Dio client)
│   ├── providers/                  # Riverpod providers
│   ├── storage/                    # Secure storage
│   └── pages/                      # Core pages
├── features/                       # Feature modules
│   ├── auth/                       # Authentication
│   │   ├── data/                   # Auth data layer
│   │   ├── domain/                 # Auth business logic
│   │   └── presentation/           # Auth UI
│   ├── booking/                    # Booking management
│   │   ├── data/                   # Booking API & models
│   │   └── presentation/           # Booking UI
│   └── trip/                       # Trip management
│       ├── data/                   # Trip API & models
│       ├── domain/                 # Trip business logic
│       └── presentation/           # Trip UI
├── pages/                          # App pages
│   ├── user/                       # User-specific pages
│   │   └── tabs/                   # User dashboard tabs
│   └── driver/                     # Driver-specific pages
│       └── tabs/                   # Driver dashboard tabs
├── services/                       # Business services
│   ├── location_service.dart       # GPS & geolocation
│   ├── places_service.dart         # Address autocomplete
│   └── trip_search_service.dart    # Trip search logic
├── widgets/                        # Reusable widgets
├── utils/                          # Utility functions
├── main.dart                       # App entry point
├── user_dashboard_page.dart        # User main screen
└── driver_dashboard_page.dart      # Driver main screen
```

## 🔄 Recent Updates (v2.0.0)

### Major Backend Migration
- ✅ **Migrated from Firebase to REST API backend**
- ✅ **Hybrid authentication:** Firebase Auth + REST API integration
- ✅ **Complete REST endpoints** for trips, bookings, and user management
- ✅ **Improved error handling** with standardized API responses

### UI/UX Improvements
- ✅ **Welcome screens** for both drivers and passengers
- ✅ **Streamlined navigation** with big action buttons
- ✅ **Driver trip details** now shows passenger information
- ✅ **Fixed booking page flashing** issue (removed infinite loop)
- ✅ **Enhanced trip cards** with better visual hierarchy

### Bug Fixes
- ✅ Fixed build errors with Color.shade700 usage
- ✅ Resolved booking list refresh loops
- ✅ Improved route matching algorithm
- ✅ Better handling of API timeouts and errors

## 🐛 Troubleshooting

### Common Issues

**1. App won't build:**
```bash
flutter clean
flutter pub get
flutter run
```

**2. Maps not showing:**
- Check internet connection (OpenStreetMap tiles require network)
- Verify location permissions are granted
- Ensure GPS is enabled on device

**3. Backend connection issues:**
- Check that backend URL is correct in `dio_client.dart`
- For Android emulator, use `10.0.2.2` instead of `localhost`
- Ensure backend server is running and accessible
- Check firewall settings

**4. Authentication errors:**
- Verify Firebase project configuration
- Check that email/password auth is enabled in Firebase Console
- Clear app data and try again

**5. Location services not working:**
- Grant location permissions when prompted
- Enable GPS on your device
- For iOS: Location usage descriptions are in `Info.plist`

### Build Issues

**Android build errors:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**iOS build errors:**
```bash
cd ios
pod deinstall
pod install
cd ..
flutter clean
flutter pub get
```

## 📝 Development

### Running Code Generation
If you modify models with JSON serialization:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 Academic Project

This project was developed under the supervision of the Computer Science Department at Philipps-Universität Marburg, Germany.

- **Institution:** Philipps-Universität Marburg
- **Department:** Computer Science (Fachbereich Mathematik und Informatik)
- **Purpose:** Educational and research purposes

All rights reserved. This project is for academic use and demonstration purposes only.

## 👥 Authors

- Ahmed Elmesery - [GitHub](https://github.com/ahmedelmeseryy)
- Sumeet Kumar - [GitHub](https://github.com/iamsumitk)

## 🙏 Acknowledgments

- OpenStreetMap for map tiles and Nominatim geocoding service
- Flutter team for the amazing framework
- Firebase for authentication services
- All contributors who have helped with the project

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on [GitHub](https://github.com/ahmedelmeseryy/CarSharing/issues)
- Contact: elmesery72@gmail.com

---

## ⚠️ Important Notice

**This is an educational project currently under active development.**

- **Purpose:** Created for learning and demonstration purposes
- **Status:** Work in progress - features may be incomplete or subject to change
- **Not Production Ready:** This application is not intended for commercial or production use
- **API Compliance:** If you use this code, ensure you comply with OpenStreetMap's [Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/) and Nominatim's [Usage Policy](https://operations.osmfoundation.org/policies/nominatim/)

Contributions, feedback, and learning from this project are welcome!
