import 'package:flutter/material.dart';
import 'add_trip_page.dart';
import 'pages/driver/driver_trip_details_page.dart';
import 'pages/driver/trip_templates_page.dart';
import 'pages/admin/seed_trips_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carsharing/main.dart'; // For ProfilePage
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/core/providers/mutation_providers.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';

class DriverDashboardPage extends ConsumerStatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  ConsumerState<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends ConsumerState<DriverDashboardPage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const DriverTripsPage(),
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
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.science),
                  tooltip: 'Seed Test Trips',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SeedTripsPage(),
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
        body: _widgetOptions.elementAt(_selectedIndex),
        floatingActionButton: _selectedIndex == 0
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: "templates",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TripTemplatesPage(),
                        ),
                      );
                    },
                    child: const Icon(Icons.bookmark),
                    tooltip: 'Trip Templates',
                    backgroundColor: Colors.orange,
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: "add_trip",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddTripPage()),
                      );
                    },
                    child: const Icon(Icons.add),
                    tooltip: 'Add New Trip',
                  ),
                ],
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.drive_eta),
              label: 'My Trips',
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

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'My Created Trips';
      case 1:
        return 'Profile';
      default:
        return 'Driver Dashboard';
    }
  }
}

class DriverTripsPage extends ConsumerStatefulWidget {
  const DriverTripsPage({super.key});

  @override
  ConsumerState<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends ConsumerState<DriverTripsPage> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _deleteTrip(String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Trip'),
        content: const Text('Are you sure you want to cancel this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Trip', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final request = CancelTripRequest(
          userId: user!.uid,
          tripId: tripId,
        );
        final notifier = ref.read(cancelTripProvider.notifier);
        await notifier.cancelTrip(request);
        
        if (!mounted) return;
        final state = ref.read(cancelTripProvider);
        state.when(
          data: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip cancelled successfully.'),
                backgroundColor: Colors.green,
              ),
            );
            notifier.reset();
            setState(() {}); // Refresh the list
          },
          error: (error, stack) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to cancel trip: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
          loading: () {},
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(
        child: Text('Please log in to view your trips.'),
      );
    }

    final tripsAsync = ref.watch(getUpcomingTripsForDriverProvider(user!.uid));
    
    print('🚗 DRIVER TRIPS: Fetching trips for driver ${user!.uid}');

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return const Center(
            child: Text(
              'You have not created any trips yet.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(getUpcomingTripsForDriverProvider(user!.uid));
          },
          child: ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              
              String formattedDate = 'N/A';
              try {
                if (trip.tripStartDateTime.isNotEmpty) {
                  // Parse the ISO 8601 date string
                  final dateTime = DateTime.parse(trip.tripStartDateTime);
                  formattedDate = DateFormat.yMd().format(dateTime);
                }
              } catch (e) {
                formattedDate = trip.tripStartDateTime;
              }
              
              final from = trip.sourceAddress.placeAddress ?? 'N/A';
              final to = trip.destinationAddress.placeAddress ?? 'N/A';
              final seats = trip.offeredSeat;
              final bookedSeats = trip.currSeats;
              final bookingCount = trip.joinedRidersId?.length ?? 0;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: bookingCount > 0
                      ? Stack(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.people, color: Colors.white),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$bookingCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : null,
                  title: Text('$from to $to'),
                  subtitle: Text('$seats seats offered • $bookedSeats booked • $formattedDate'),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _deleteTrip(trip.tripId ?? ''),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverTripDetailsPage(
                          trip: trip,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading trips: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(getUpcomingTripsForDriverProvider(user!.uid));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
 