# How to Migrate Your Screens to REST API

## The Problem

Your existing screens still use Firebase services. You need to replace them with the new REST API infrastructure.

## The Solution Pattern

Here's how to migrate any screen step-by-step:

---

## Example: Migrating `ride_list_page.dart`

### BEFORE (Current Firebase Code)
```dart
class _RideListPageState extends State<RideListPage> {
  final TripSearchService _tripSearchService = TripSearchService();
  List<Trip> _trips = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      final trips = await _tripSearchService.searchTrips(
        origin: widget.searchQuery,
        destination: 'Any',
      );
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Available Rides')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Available Rides')),
      body: _trips.isEmpty
          ? const Center(child: Text('No trips found'))
          : ListView.builder(
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                return TripCard(trip: trip);
              },
            ),
    );
  }
}
```

### AFTER (Using REST API + Riverpod)
```dart
class _RideListPageState extends ConsumerWidget {
  final String searchQuery;

  const _RideListPageState({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider for trip search
    final tripsAsync = ref.watch(
      searchMatchingRouteProvider(
        origin: searchQuery,
        destination: 'Any',
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Available Rides')),
      body: tripsAsync.when(
        // When loading
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        // When error
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(
                  searchMatchingRouteProvider(
                    origin: searchQuery,
                    destination: 'Any',
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        // When success
        data: (trips) => trips.isEmpty
            ? const Center(
                child: Text('No trips found'),
              )
            : ListView.builder(
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return TripCard(trip: trip);
                },
              ),
      ),
    );
  }
}
```

---

## Key Changes Explained

### 1. Change Extends to ConsumerWidget
```dart
// BEFORE
class _RideListPageState extends State<RideListPage> {

// AFTER
class _RideListPageState extends ConsumerWidget {
```

### 2. Remove Manual State Management
```dart
// REMOVE THESE:
List<Trip> _trips = [];
bool _isLoading = false;

// REMOVE THIS:
@override
void initState() {
  super.initState();
  _loadTrips();
}

// REMOVE THIS:
void _loadTrips() async { ... }
```

### 3. Use Riverpod Provider
```dart
// ADD THIS at top of build():
final tripsAsync = ref.watch(
  searchMatchingRouteProvider(
    origin: searchQuery,
    destination: 'Any',
  ),
);
```

### 4. Replace setState() with .when()
```dart
// BEFORE:
if (_isLoading) { ... }
if (_trips.isEmpty) { ... }
return TripCard(trip: trip);

// AFTER:
tripsAsync.when(
  loading: () => ...,
  error: (error, st) => ...,
  data: (trips) => ...,
);
```

---

## Step-by-Step Migration Process

### Step 1: Change Widget Type
```dart
// Change FROM:
class RideListPage extends StatefulWidget {
  final String searchQuery;
  const RideListPage({required this.searchQuery});
  @override
  State<RideListPage> createState() => _RideListPageState();
}

// Change TO:
class RideListPage extends ConsumerWidget {
  final String searchQuery;
  const RideListPage({required this.searchQuery, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... rest of build code
  }
}

// And REMOVE the State class
// DELETE: class _RideListPageState extends State<RideListPage> { ... }
```

### Step 2: Import Riverpod
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';
```

### Step 3: Add Provider Watch
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final tripsAsync = ref.watch(
    searchMatchingRouteProvider(
      origin: searchQuery,
      destination: 'Any',
    ),
  );
  
  // ... rest of build
}
```

### Step 4: Replace Build Logic
```dart
return Scaffold(
  appBar: AppBar(title: const Text('Available Rides')),
  body: tripsAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, st) => Center(child: Text('Error: $error')),
    data: (trips) => trips.isEmpty
        ? const Center(child: Text('No trips found'))
        : ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) => TripCard(trip: trips[index]),
          ),
  ),
);
```

### Step 5: Test
- Run app: `flutter run`
- Navigate to ride search
- Verify trips load from REST API
- Check debug console shows the request

---

## Available Riverpod Providers

You can use these providers in any screen:

### Query Providers (Read-Only)
```dart
// Search for matching routes
ref.watch(searchMatchingRouteProvider(
  origin: String,
  destination: String,
))

// Get driver's posted trips
ref.watch(getDriverTripsProvider(driverId: String))

// Get trips by status
ref.watch(getTripsByStatusProvider(status: String))

// Get driver offers
ref.watch(getDriverOffersProvider(driverId: String))

// Get passenger rides
ref.watch(getPassengerRidesProvider(passengerId: String))
```

### Mutation Providers (Create/Update/Delete)
```dart
// Create an offer
ref.watch(createOfferMutationProvider)

// Join a trip
ref.watch(joinTripMutationProvider)

// Cancel a trip
ref.watch(cancelTripMutationProvider)

// Cancel a booking
ref.watch(cancelBookingMutationProvider)

// Update trip status
ref.watch(updateTripStatusMutationProvider)
```

---

## Example: Using a Mutation

When user clicks "Book" button:

```dart
ElevatedButton(
  onPressed: () async {
    // Get the mutation provider
    final joinTrip = ref.watch(joinTripMutationProvider);
    
    try {
      // Call it with data
      await joinTrip.call(JoinTripRequest(
        tripId: trip.id,
        passengerId: userId,
        numberOfSeats: 1,
      ));
      
      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully booked trip!')),
      );
      
      // Refresh the trips list
      ref.refresh(getPassengerRidesProvider(passengerId: userId));
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  child: const Text('Book Seat'),
)
```

---

## Screens to Migrate

### High Priority (Core Flow)
1. **ride_list_page.dart** - Uses TripSearchService
   - Replace with: `searchMatchingRouteProvider`

2. **driver_dashboard_page.dart** - Shows driver's trips
   - Replace with: `getDriverTripsProvider`

3. **user_dashboard_page.dart** - Shows user's bookings
   - Replace with: `getPassengerRidesProvider`

4. **ride_detail_page.dart** - Shows single trip
   - Already receives trip object, less change needed

### Medium Priority (Supporting Features)
5. **add_trip_page.dart** - Driver creates offer
   - Replace with: `createOfferMutationProvider`

6. **seat_selection_page.dart** - Passenger books seat
   - Replace with: `joinTripMutationProvider`

### Low Priority (Admin/Settings)
7. **profile_page.dart** - User profile
   - May need REST endpoint for profile updates
   - Can remain with Firebase temporarily

---

## Migration Checklist Template

For each screen, use this checklist:

```
Screen: ride_list_page.dart
- [ ] Change extends to ConsumerWidget
- [ ] Import flutter_riverpod & app_providers
- [ ] Remove State class or convert to build method
- [ ] Remove initState(), setState(), and manual fields
- [ ] Add ref.watch(provider) call
- [ ] Replace if/else with .when()
- [ ] Test data loads correctly
- [ ] Test error handling
- [ ] Test empty state
- [ ] Test refresh/retry button
```

---

## Common Patterns

### Loading with Spinner
```dart
tripsAsync.when(
  loading: () => const CircularProgressIndicator(),
  error: (err, st) => Text('Error'),
  data: (trips) => ListView(...),
);
```

### Refresh/Retry
```dart
// In error builder:
ElevatedButton(
  onPressed: () => ref.refresh(searchMatchingRouteProvider(...)),
  child: const Text('Retry'),
)
```

### Conditional UI
```dart
tripsAsync.when(
  data: (trips) {
    if (trips.isEmpty) return const Text('No trips');
    if (trips.length < 3) return const Text('Few trips available');
    return ListView(...);
  },
  loading: () => const Spinner(),
  error: (e, st) => Text('Error: $e'),
)
```

### Multiple Providers
```dart
// Watch multiple providers at once
final trips = ref.watch(tripsProvider);
final user = ref.watch(userProvider);

// Use async.when for combined loading
final both = ref.watch(Providers.combine([
  tripsProvider,
  userProvider,
]));

both.when(
  data: (results) {
    final trips = results[0];
    final user = results[1];
    return ...
  },
  ...
)
```

---

## Troubleshooting Migration

### Issue: "ref is undefined"
**Solution:** Make sure build method parameter includes `WidgetRef ref`
```dart
Widget build(BuildContext context, WidgetRef ref) {
  // ref is now available
}
```

### Issue: "Provider not found"
**Solution:** Import from app_providers
```dart
import 'package:carsharing/core/providers/app_providers.dart';
```

### Issue: "Data always loading"
**Solution:** Check backend is running at http://34.30.27.79:8080

### Issue: "401 Unauthorized"
**Solution:** User not authenticated, need to add JWT token first

### Issue: "ConsumerWidget not defined"
**Solution:** Add import
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

---

## After Migration

### Testing Checklist
- [ ] App starts without errors
- [ ] Navigate to screen
- [ ] Data loads from REST API
- [ ] Error handling works
- [ ] Refresh/retry works
- [ ] Operations complete successfully
- [ ] Debug console shows correct API calls

### Performance Check
- [ ] Data loads quickly (< 3 seconds)
- [ ] No unnecessary API calls
- [ ] Proper caching (Riverpod handles this)
- [ ] Smooth UI transitions

### Before Deleting Firebase Code
- [ ] All screens use REST API
- [ ] No Firebase imports in UI files
- [ ] All functionality works with REST
- [ ] Users authenticated with backend JWT

---

## Next: Gradual vs Complete Migration

### Option 1: Gradual (Recommended)
- Migrate one screen at a time
- Keep Firebase as fallback
- Test each screen thoroughly
- Switch over gradually

### Option 2: Complete
- Migrate all screens at once
- Remove Firebase immediately
- Faster but riskier
- Need thorough testing

### Option 3: Side-by-Side
- Keep both Firebase and REST
- Let users choose
- Gradually phase out Firebase
- Safest but most complex

---

**Questions?** Check the debug console or documentation files!
