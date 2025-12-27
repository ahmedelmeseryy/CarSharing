# Route Matching Implementation

## ✅ What Was Implemented

### 1. Route Matching Service
- **File**: `lib/services/route_matching_service.dart`
- **Features**:
  - Haversine formula for distance calculation between coordinates
  - Finds trips where user's origin is near trip origin or any stop
  - Finds trips where user's destination is near trip destination or any stop
  - Ensures dropoff point is after pickup point (route direction validation)
  - Time window matching (flexible time matching)
  - Match scoring (0-100, higher = better match)
  - Stream-based matching for real-time updates

### 2. Enhanced Trip Search Page
- **File**: `lib/pages/user/trip_search_page.dart`
- **Updates**:
  - Now uses route matching service
  - Shows loading indicator during search
  - Navigates to results page with matches
  - Handles errors gracefully

### 3. Trip Search Results Page
- **File**: `lib/pages/user/trip_search_results_page.dart`
- **Features**:
  - Displays matching trips sorted by match score
  - Shows match percentage badge (color-coded)
  - Displays pickup and dropoff points
  - Shows distance to pickup/dropoff locations
  - Displays trip details (date, price, seats, driver)
  - Clickable cards to view trip details

### 4. Updated User Dashboard
- **File**: `lib/user_dashboard_page.dart`
- **Changes**:
  - Added search icon button in AppBar
  - Opens advanced search page with route matching

## 🎯 How Route Matching Works

### Algorithm Flow:

1. **User Input**:
   - User enters origin address (with coordinates)
   - User enters destination address (with coordinates)
   - Optional: User selects preferred date

2. **Trip Filtering**:
   - Get all trips from Firestore
   - Filter trips that have coordinates
   - Filter by date (if provided) within time window

3. **Pickup Point Matching**:
   - Check distance from user origin to:
     - Trip origin
     - All intermediate stops
   - Find closest point within search radius (default: 10 km)
   - Record pickup location and distance

4. **Dropoff Point Matching**:
   - Check distance from user destination to:
     - Trip destination
     - All intermediate stops (after pickup point)
   - Find closest point within search radius
   - Record dropoff location and distance

5. **Match Scoring**:
   - Calculate match score (0-100):
     - Pickup score: 100 - (distance/radius * 50)
     - Dropoff score: 100 - (distance/radius * 50)
     - Final score: Average of pickup and dropoff scores
   - Higher score = closer distances = better match

6. **Results**:
   - Sort matches by score (best first)
   - Display results with match details

## 📊 Match Score Interpretation

- **70-100%**: Excellent match (very close to route)
- **50-70%**: Good match (reasonable distance)
- **0-50%**: Fair match (farther but still within radius)

## 🔧 Configuration

### Search Radius
Default: 10 km (configurable)
```dart
RouteMatchingService.findMatchingTrips(
  searchRadius: 15.0, // 15 km radius
  ...
)
```

### Time Window
Default: ±2 hours (configurable)
```dart
RouteMatchingService.findMatchingTrips(
  timeWindowHours: 3, // ±3 hours
  ...
)
```

## 📋 Example Usage

### Basic Search:
```dart
final matches = await RouteMatchingService.findMatchingTrips(
  userFromLat: 52.5200,
  userFromLng: 13.4050,
  userToLat: 48.1351,
  userToLng: 11.5820,
);
```

### With Date Filter:
```dart
final matches = await RouteMatchingService.findMatchingTrips(
  userFromLat: 52.5200,
  userFromLng: 13.4050,
  userToLat: 48.1351,
  userToLng: 11.5820,
  preferredDate: DateTime(2024, 2, 15, 14, 30),
  searchRadius: 15.0,
  timeWindowHours: 2,
);
```

### Real-time Updates (Stream):
```dart
RouteMatchingService.findMatchingTripsStream(
  userFromLat: 52.5200,
  userFromLng: 13.4050,
  userToLat: 48.1351,
  userToLng: 11.5820,
).listen((matches) {
  // Update UI with new matches
});
```

## 🎨 UI Features

### Search Results Display:
- **Match Badge**: Color-coded percentage (green/orange/grey)
- **Route Info**: Shows trip origin → destination
- **Pickup/Dropoff**: Shows where user gets on/off
- **Distance Info**: Shows distance to pickup/dropoff points
- **Trip Details**: Date, time, price, seats, driver name
- **Clickable**: Tap to view full trip details

## 🔍 Matching Criteria

A trip matches if:
1. ✅ Trip has coordinates (fromLatitude, fromLongitude, toLatitude, toLongitude)
2. ✅ User's origin is within radius of trip origin OR any stop
3. ✅ User's destination is within radius of trip destination OR any stop after pickup
4. ✅ Dropoff point is after pickup point (route direction)
5. ✅ (Optional) Trip date matches user's preferred date within time window

## 🚀 Performance Considerations

- **Current**: Fetches all trips and filters client-side
- **Future Optimization**: 
  - Add Firestore queries to filter by date first
  - Use geohash for spatial indexing
  - Implement pagination for large datasets
  - Cache recent searches

## 📝 Data Requirements

For route matching to work, trips must have:
```json
{
  "fromLatitude": 52.5200,
  "fromLongitude": 13.4050,
  "toLatitude": 48.1351,
  "toLongitude": 11.5820,
  "stops": [
    {
      "latitude": 49.4452,
      "longitude": 11.0817,
      "address": "Stop address"
    }
  ]
}
```

## 🎯 Next Steps

1. **Optimize Queries**: Add Firestore indexes and date filtering
2. **Geohash Support**: For better spatial queries
3. **Route Visualization**: Show matched route on map
4. **Multiple Routes**: Support for trips with multiple route options
5. **User Preferences**: Save search history and preferences

## 📚 Technical Details

### Haversine Formula
Used to calculate great-circle distance between two points on Earth:
```
a = sin²(Δφ/2) + cos(φ1) × cos(φ2) × sin²(Δλ/2)
c = 2 × atan2(√a, √(1−a))
d = R × c
```
Where:
- φ = latitude
- λ = longitude
- R = Earth radius (6371 km)

### Match Score Calculation
```
pickupScore = 100 - (distanceToPickup / searchRadius * 50)
dropoffScore = 100 - (distanceToDropoff / searchRadius * 50)
matchScore = (pickupScore + dropoffScore) / 2
```

This ensures:
- Closer distances = higher scores
- Maximum score of 100 for perfect matches
- Scores scale with search radius
