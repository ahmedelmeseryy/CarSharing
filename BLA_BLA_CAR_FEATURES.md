# BlaBlaCar-Style Features Implementation

This document outlines the implementation of BlaBlaCar-style features for the car sharing app.

## ✅ Completed Features

### 1. Enhanced Trip Creation with Exact Addresses
- **Location**: `lib/add_trip_page.dart`
- **Changes**:
  - Replaced city dropdowns with exact address input fields
  - Added support for latitude/longitude coordinates (ready for Maps API integration)
  - Added placeholder for Maps API integration (UI buttons ready)

### 2. Intermediate Stops Support
- **Location**: `lib/add_trip_page.dart`, `lib/models/trip_stop.dart`
- **Features**:
  - Drivers can add multiple intermediate stops
  - Each stop has an address, order, and optional coordinates
  - Stops are displayed in order with ability to add/remove
  - Stops are saved in the trip data structure

### 3. Time Estimation
- **Location**: `lib/add_trip_page.dart`
- **Features**:
  - Basic time estimation calculation (placeholder algorithm)
  - Displays estimated duration in hours and minutes
  - Updates automatically when addresses or stops change
  - Ready for Maps API integration for accurate calculations

### 4. Trip Templates
- **Location**: `lib/add_trip_page.dart`, `lib/pages/driver/trip_templates_page.dart`
- **Features**:
  - Drivers can save trips as templates
  - Templates include: origin, destination, stops, seats, and price
  - Templates are stored in Firestore under `users/{userId}/trip_templates`
  - Drivers can view, use, and delete templates
  - Quick access button in driver dashboard

### 5. Enhanced Data Model
- **Location**: `lib/models/trip_stop.dart`
- **New Fields in Trip Document**:
  ```dart
  {
    'from': 'Legacy field',
    'to': 'Legacy field',
    'fromAddress': 'Exact address',
    'toAddress': 'Exact address',
    'fromLatitude': double?,
    'fromLongitude': double?,
    'toLatitude': double?,
    'toLongitude': double?,
    'stops': [
      {
        'address': 'Stop address',
        'order': 1,
        'latitude': double?,
        'longitude': double?,
      }
    ],
    'estimatedDurationMinutes': int?,
    'estimatedArrivalTime': Timestamp?,
    // ... other existing fields
  }
  ```

## 🚧 Pending Features

### 1. Route Matching Algorithm
**Status**: Not yet implemented  
**Location**: `lib/pages/user/tabs/available_trips_tab.dart` (needs update)

**Requirements**:
- Users input exact start and destination addresses
- System finds trips where:
  - User's start point is within radius of trip origin or any stop
  - User's destination is within radius of trip destination or any stop
  - Trip date/time matches user's timeframe (with flexibility)
  - Route direction matches (user going same direction)

**Implementation Plan**:
1. Create route matching service/utility
2. Calculate distance between points (Haversine formula or Maps API)
3. Filter trips based on:
   - Start point proximity (within X km of origin or stops)
   - End point proximity (within X km of destination or stops)
   - Time window matching
   - Route direction validation
4. Update search UI to accept exact addresses instead of city names

### 2. Driver Confirmation Workflow
**Status**: Not yet implemented  
**Location**: `lib/pages/driver/driver_trip_details_page.dart` (needs update)

**Requirements**:
- Bookings start as "pending" status
- Driver sees pending bookings and can confirm or reject
- Only confirmed bookings count toward seat availability
- User receives notification when booking is confirmed/rejected

**Implementation Plan**:
1. Update booking creation to set status as "pending" instead of "confirmed"
2. Add confirmation UI in driver trip details page
3. Add "Confirm" and "Reject" buttons for pending bookings
4. Update seat availability logic to reserve seats for pending bookings
5. Add notification system (optional)

### 3. Seat Selection UI
**Status**: Not yet implemented  
**Location**: `lib/pages/user/trip_details_page.dart`, `lib/pages/user/payment_page.dart`

**Requirements**:
- Show visual seat map (e.g., 4-seat car layout)
- Allow users to select specific seats
- Show which seats are already booked
- Store selected seat numbers in booking

**Implementation Plan**:
1. Create seat selection widget/component
2. Display car layout with available/booked seats
3. Allow seat selection before booking
4. Update booking data model to include `selectedSeats: [1, 3]` array
5. Update UI to show selected seats in booking details

### 4. Maps API Integration
**Status**: Placeholder ready  
**Location**: `lib/add_trip_page.dart`

**Requirements**:
- Address autocomplete/suggestions
- Address verification
- Accurate distance and time calculations
- Route visualization

**Implementation Plan**:
1. Add Google Maps or similar service package
2. Implement address autocomplete
3. Geocode addresses to get coordinates
4. Calculate accurate routes and durations
5. Display route on map (optional)

## 📋 Data Structure Changes

### Trip Document (Enhanced)
```json
{
  "from": "Berlin",  // Legacy, kept for backward compatibility
  "to": "Munich",   // Legacy
  "fromAddress": "Hauptbahnhof, Berlin, Germany",
  "toAddress": "Marienplatz, Munich, Germany",
  "fromLatitude": 52.5200,
  "fromLongitude": 13.4050,
  "toLatitude": 48.1351,
  "toLongitude": 11.5820,
  "stops": [
    {
      "address": "Nuremberg Central Station, Nuremberg, Germany",
      "order": 1,
      "latitude": 49.4452,
      "longitude": 11.0817
    }
  ],
  "estimatedDurationMinutes": 240,
  "estimatedArrivalTime": "2024-02-15T18:30:00Z",
  "date": "2024-02-15T14:30:00Z",
  "seats": 4,
  "price": 35.50,
  "driverId": "user-uuid",
  "driverName": "John Doe",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

### Booking Document (Needs Update for Confirmation)
```json
{
  "tripId": "trip-uuid",
  "userId": "user-uuid",
  "driverId": "driver-uuid",
  "seats": 2,
  "selectedSeats": [1, 3],  // NEW: Specific seat numbers
  "totalPrice": 71.00,
  "paymentMethod": "cash",
  "status": "pending",  // CHANGED: Now starts as pending
  "confirmedAt": null,  // NEW: Timestamp when driver confirms
  "rejectedAt": null,   // NEW: Timestamp when driver rejects
  "tripFrom": "Berlin",
  "tripTo": "Munich",
  "tripDate": "2024-02-15T14:30:00Z",
  "passengerName": "Jane Smith",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

## 🔧 Backend API Updates Needed

If migrating to custom backend, update the API specification:

### New Trip Creation Endpoint
```json
POST /trips
{
  "fromAddress": "Exact address",
  "toAddress": "Exact address",
  "fromLatitude": 52.5200,
  "fromLongitude": 13.4050,
  "toLatitude": 48.1351,
  "toLongitude": 11.5820,
  "stops": [...],
  "date": "2024-02-15T14:30:00Z",
  "seats": 4,
  "price": 35.50
}
```

### New Search Endpoint
```json
GET /trips/search?fromLat={lat}&fromLng={lng}&toLat={lat}&toLng={lng}&radius={km}&date={date}&timeWindow={hours}
```

### Booking Confirmation Endpoint
```json
PUT /bookings/{bookingId}/confirm
PUT /bookings/{bookingId}/reject
```

## 🎯 Next Steps

1. **Implement Route Matching** (High Priority)
   - Create route matching algorithm
   - Update search functionality
   - Test with various route scenarios

2. **Add Driver Confirmation** (High Priority)
   - Update booking status workflow
   - Add confirmation UI
   - Update seat availability logic

3. **Implement Seat Selection** (Medium Priority)
   - Design seat selection UI
   - Update booking flow
   - Store seat assignments

4. **Integrate Maps API** (Medium Priority)
   - Choose provider (Google Maps, Mapbox, etc.)
   - Implement autocomplete
   - Calculate accurate routes

5. **Testing** (Ongoing)
   - Test trip creation with stops
   - Test template functionality
   - Test route matching
   - Test booking confirmation flow

## 📝 Notes

- All new fields are optional/nullable to maintain backward compatibility
- Legacy `from` and `to` fields are kept for existing trips
- Maps API integration is prepared but not yet implemented
- Route matching algorithm needs to be implemented
- Driver confirmation workflow needs to be added
- Seat selection UI needs to be designed and implemented
