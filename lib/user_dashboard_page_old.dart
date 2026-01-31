import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:carsharing/pages/user/tabs/available_trips_tab.dart';
import 'package:carsharing/pages/user/trip_search_page.dart';
import 'package:carsharing/pages/user/trip_search_test_page.dart';
import 'package:carsharing/main.dart'; // For ProfilePage
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';

class UserDashboardPage extends StatefulWidget {
  final int initialIndex;
  
  const UserDashboardPage({super.key, this.initialIndex = 0});

  @override
  _UserDashboardPageState createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  late int _selectedIndex;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Widget _getAvailableTripsWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TripSearchTestPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Advanced Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TripSearchPage(),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by city...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: AvailableTripsTab(searchQuery: _searchQuery),
    );
  }

  static List<Widget> _getWidgetOptions(String searchQuery) => <Widget>[
    AvailableTripsTab(searchQuery: searchQuery),
    const BookedTripsPage(),
    const FavoriteTripsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: _selectedIndex == 0 
            ? _getAvailableTripsWidget()
            : _getWidgetOptions(_searchQuery).elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Available',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Booked',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class BookedTripsPage extends ConsumerStatefulWidget {
  const BookedTripsPage({super.key});

  @override
  ConsumerState<BookedTripsPage> createState() => _BookedTripsPageState();
}

class _BookedTripsPageState extends ConsumerState<BookedTripsPage> {
  @override
  Widget build(BuildContext context) {
    final tokenStorage = ref.read(secureStorageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booked Trips'),
      ),
      body: FutureBuilder<String?>(
        future: tokenStorage.getUserId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userId = snapshot.data;
          if (userId == null || userId.isEmpty) {
            return const Center(
              child: Text('Log in to view your bookings.'),
            );
          }

          print('🔍 DEBUG: Fetching bookings for userId: $userId');

          final bookingsAsync = ref.watch(
            getUpcomingBookingsForPassengerProvider(userId),
          );
          
          // Get local cached bookings (workaround for backend issue)
          final localBookings = ref.watch(localBookingsCacheProvider(userId));

          return bookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) {
              print('❌ ERROR fetching bookings: $err');
              print('📍 Stack: $stack');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Error: $err'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(
                            getUpcomingBookingsForPassengerProvider(userId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
            data: (data) {
              var bookings = (data as List).cast<PassengerRideResponse>();
              
              // Deduplicate by tripId (in case there are duplicates in API response)
              final seen = <String>{};
              bookings = bookings.where((b) {
                if (seen.contains(b.tripId)) {
                  print('⚠️ DEBUG: Duplicate tripId found: ${b.tripId}, removing');
                  return false;
                }
                seen.add(b.tripId);
                return true;
              }).toList();
              
              // Merge with local bookings (only those not in API)
              final apiTripIds = bookings.map((b) => b.tripId).toSet();
              final uniqueLocalBookings = localBookings
                  .where((b) => !apiTripIds.contains(b.tripId))
                  .toList();
              
              bookings = [...bookings, ...uniqueLocalBookings];
              
              print('✅ DEBUG: Received ${bookings.length} bookings (${(data as List).length} from API, deduplicated to ${seen.length}, + ${uniqueLocalBookings.length} from cache)');
              if (bookings.isNotEmpty) {
                print('📌 First booking tripId: ${bookings[0].tripId}');
              }

              if (bookings.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                        getUpcomingBookingsForPassengerProvider(userId));
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 60),
                      const Center(
                        child: Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'You have no booked trips yet.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            localBookings.isNotEmpty 
                              ? 'Your recent bookings are shown below (syncing with backend...)'
                              : 'Search for trips and book one to get started!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(
                      getUpcomingBookingsForPassengerProvider(userId));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final parsedTripDate =
                        DateTime.tryParse(booking.tripStartDateTime);
                    final tripDate = parsedTripDate != null
                        ? DateFormat.yMd()
                            .add_Hm()
                            .format(parsedTripDate.toLocal())
                        : booking.tripStartDateTime;
                    final fare = (booking.estimatedFare ?? 0.0).toStringAsFixed(2);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Route
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    booking.pickupLocation.placeAddress ??
                                        'From',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.flag,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    booking.dropoffLocation.placeAddress ??
                                        'To',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            // Booking details
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date & Time',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      tripDate,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Seats',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      '${booking.bookedSeats}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Price',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      '€$fare',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: booking.isActive
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: booking.isActive
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                booking.statusLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: booking.isActive
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            if (booking.isActive) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.cancel, size: 18),
                                  label: const Text('Cancel booking'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    side: BorderSide(color: Colors.red.shade200),
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Cancel booking?'),
                                        content: const Text(
                                          'Are you sure you want to cancel this booking?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('No'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Yes, cancel'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm != true) return;

                                    try {
                                      final request = CancelTripRequest(
                                        userId: userId,
                                        tripId: booking.tripId,
                                        rideId: booking.rideId,
                                        cancellationReason: 'User cancelled',
                                      );

                                      final message = await ref
                                          .read(bookingRepositoryProvider)
                                          .cancelBooking(request);

                                      if (!mounted) return;

                                      ref
                                          .read(localBookingsCacheProvider(userId).notifier)
                                          .removeBooking(
                                            rideId: booking.rideId,
                                            tripId: booking.tripId,
                                          );

                                      ref.invalidate(
                                        getUpcomingBookingsForPassengerProvider(userId),
                                      );

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(message)),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Cancel failed: $e')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FavoriteTripsPage extends StatelessWidget {
  const FavoriteTripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Trips'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Favorites are temporarily disabled while the app uses REST. This will return once a REST endpoint for favorites is available.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}