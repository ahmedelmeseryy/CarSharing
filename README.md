# Car Sharing Mobile App

A feature-rich car-sharing application built with Flutter and Firebase, designed to connect drivers with passengers. The app provides a seamless experience for both creating and booking trips, with dedicated interfaces for user and driver roles.

## Key Features

### For Users
- **Trip Search:** Find available trips by searching for destinations.
- **Trip Details:** View comprehensive trip information, including route, date, price, available seats, and driver details.
- **Driver Profiles:** Tap on a driver's photo to view their profile, including ratings, reviews, and vehicle information.
- **Booking System:**
    - Select the number of seats.
    - Choose between cash or card payment.
    - Receive a booking confirmation.
- **Booking Management:** View a list of all booked trips with their status.
- **Favorites:** Mark trips as favorites for easy access later.

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
- **Key Packages:**
    - `cloud_firestore`: For database interaction.
    - `firebase_auth`: For user authentication.
    - `dropdown_search`: For searchable dropdowns in the trip creation form.
    - `intl`: For date and time formatting.

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
    - **`main.dart`**: The entry point of the application, containing routing and theme setup.
    - **`add_trip_page.dart`**: Form for drivers to create new trips.
    - **`user_dashboard_page.dart`**: Main dashboard for users with tabs for available trips, bookings, and favorites.
    - **`driver_dashboard_page.dart`**: Main dashboard for drivers with tabs for their trips and bookings.
- **`assets/`**: Contains static assets like images or JSON files.
- **`pubspec.yaml`**: Defines project dependencies and metadata.
