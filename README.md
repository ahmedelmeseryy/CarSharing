# Car Sharing Mobile App

A feature-rich car-sharing application built with Flutter and Firebase, designed to connect drivers with passengers. The app provides a seamless experience for both creating and booking trips, with dedicated interfaces for user and driver roles.

## Key Features

### For Users
- **Trip Search:** Find available trips by searching for destinations with autocomplete suggestions.
- **Address Autocomplete:** Type in a location and get real-time address suggestions powered by OpenStreetMap Nominatim with:
    - Debounced input (300ms) to reduce server load.
    - Fallback suggestions for common cities when network is unavailable.
    - "No matching address" feedback when no results are found.
    - Resilient network handling with timeout, retries, and exponential backoff.
- **Trip Details:** View comprehensive trip information in a card-based layout, including route, date, price, available seats, driver avatar, and driver details.
- **Driver Profiles:** Tap on a driver's photo to view their profile, including ratings, reviews, and vehicle information.
- **Booking System:**
    - Select the number of seats.
    - Choose between cash or card payment.
    - Receive a booking confirmation.
- **Booking Management:** View a list of all booked trips with their status in an improved card layout.
- **Favorites:** Mark trips as favorites for easy access later with visual indicator.

### For Drivers
- **Trip Creation:** Add new trips with details like starting point, destination, date, time, seats, and price.
- **Trip Management:** View a list of all created trips.
- **Trip Details:** See detailed information for each trip, including a list of passengers who have booked.
- **Booking Management:**
    - View all bookings for their trips.
    - **Cancel** specific user bookings, which automatically refunds the seats to the trip.
- **Driver Profile:** Manage personal and vehicle information, which is displayed to users.

## Technical Stack

- **Frontend:** Flutter
- **Backend & Database:** Firebase (Firestore, Authentication)
- **State Management:** `setState`
- **Geolocation & Maps:** 
    - Google Maps for route visualization
    - OpenStreetMap Nominatim for address suggestions
    - Location services for GPS tracking
- **Key Packages:**
    - `cloud_firestore`: For database interaction.
    - `firebase_auth`: For user authentication.
    - `dropdown_search`: For searchable dropdowns in the trip creation form.
    - `intl`: For date and time formatting.
    - `http`: For API calls to address suggestion service.
    - `geolocator`: For GPS location access.

## Getting Started

### Prerequisites
- Flutter SDK
- A Firebase project with Firestore and Authentication enabled.

### Installation & Setup

1.  **Clone the repository:**
    ```sh
    git clone [your-repo-url]
    cd carsharing
    ```

2.  **Set up Firebase:**
    - Place your `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files in the appropriate directories.
    - Ensure your Firebase project has the `users`, `trips`, and `bookings` collections.

3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

4.  **Run the app:**
    ```sh
    flutter run
    ```

## Project Structure Highlights

- **`lib/`**: Contains all the Dart code.
    - **`pages/`**: Contains the main pages of the app.
        - **`user/`**: User-specific pages and tabs.
        - **`driver/`**: Driver-specific pages.
    - **`widgets/`**: Reusable UI components.
        - **`trip_card.dart`**: Card widget for displaying trip information with elegant layout.
        - **`address_autocomplete_field.dart`**: Autocomplete input field for location selection.
        - **`map_location_picker.dart`**: Map-based location picker.
    - **`services/`**: Business logic and external API integration.
        - **`places_service.dart`**: Nominatim integration with caching, retry logic, and fallback suggestions.
        - **`location_service.dart`**: GPS and geolocation utilities.
        - **`route_matching_service.dart`**: Route optimization and matching logic.
    - **`models/`**: Data models for trips, users, and bookings.
    - **`utils/`**: Utility functions and helpers.
    - **`main.dart`**: The entry point of the application, containing routing and theme setup.
    - **`add_trip_page.dart`**: Form for drivers to create new trips.
    - **`user_dashboard_page.dart`**: Main dashboard for users with tabs for available trips, bookings, and favorites.
    - **`driver_dashboard_page.dart`**: Main dashboard for drivers with tabs for their trips and bookings.
- **`assets/`**: Contains static assets like images or JSON files.
- **`pubspec.yaml`**: Defines project dependencies and metadata.

## Recent Updates (v1.1.0)

### Autocomplete & Address Suggestions
- **Debounced input:** Address suggestions now debounce for 300ms to reduce server load and improve responsiveness.
- **Network resilience:** Implemented timeout (5s), automatic retries with exponential backoff for transient failures (HTTP 418, 429, 5xx errors).
- **Fallback suggestions:** Common cities (e.g., Marburg, Berlin, Munich) are cached locally and displayed even when the remote service is unavailable.
- **Better UX feedback:** "No matching address" message is shown when no suggestions are found, with clear indication of loading/error states.

### Trip Display Improvements
- **Card-based layout:** Trips are now displayed in elegant cards with:
    - Start and destination locations prominently displayed.
    - Date and time information.
    - Available seats and pricing.
    - Driver avatar and name.
    - Favorite toggle button.
- **Enhanced responsiveness:** Cards are optimized for different screen sizes.

### Backend Improvements
- **Places service:** Added in-memory TTL cache with coalescing to reduce redundant API calls.
- **Stale cache handling:** When cache expires, stale data is returned immediately while a background refresh fetches fresh data.
- **Request optimization:** Improved User-Agent and polite request patterns to comply with API rate limits.

## Getting Started
