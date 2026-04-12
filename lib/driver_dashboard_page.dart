import 'package:flutter/material.dart';
import 'pages/driver/driver_trip_details_page.dart';
import 'pages/driver/tabs/driver_welcome_tab.dart';
import 'package:carsharing/main.dart'; // For ProfilePage
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/core/providers/mutation_providers.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/core/storage/secure_storage.dart';

class DriverDashboardPage extends ConsumerStatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  ConsumerState<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends ConsumerState<DriverDashboardPage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const DriverWelcomeTab(),
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
        actions: _selectedIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () {
                    final state = context.findAncestorStateOfType<_DriverTripsPageState>();
                    state?._refresh();
                  },
                ),
              ]
            : null,
      ),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
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
        return 'Welcome';
      case 1:
        return 'My Created Trips';
      case 2:
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
  String? _userId;
  bool _userIdLoaded = false;

  Future<void> _loadUserId() async {
    final id = await TokenStorage().getUserId();
    if (mounted) {
      setState(() {
        _userId = id;
        _userIdLoaded = true;
      });
    }
  }

  void _refresh() {
    if (_userId != null) {
      ref.invalidate(getUpcomingTripsForDriverProvider(_userId!));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserId();
    // Listen to cancellation state changes
    ref.listenManual(cancelTripProvider, (previous, next) {
      if (!mounted) return;

      next.when(
        data: (message) {
          if (message.isNotEmpty) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip cancelled successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            if (_userId != null) {
              ref.invalidate(getUpcomingTripsForDriverProvider(_userId!));
            }
            ref.read(cancelTripProvider.notifier).reset();
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling trip: $error'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          if (_userId != null) {
            ref.invalidate(getUpcomingTripsForDriverProvider(_userId!));
          }
          ref.read(cancelTripProvider.notifier).reset();
        },
        loading: () {},
      );
    });
  }

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
      if (!mounted) return;

      final request = CancelTripRequest(
        userId: _userId ?? '',
        tripId: tripId,
      );
      
      // Show loading state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cancelling trip...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Call cancelTrip - the listener will handle success/error
      final notifier = ref.read(cancelTripProvider.notifier);
      await notifier.cancelTrip(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_userIdLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Session expired. Please log in again.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }

    final tripsAsync = ref.watch(getUpcomingTripsForDriverProvider(_userId!));

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
            ref.invalidate(getUpcomingTripsForDriverProvider(_userId!));
          },
          child: ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              
              String formattedDate = 'N/A';
              try {
                if (trip.tripStartDateTime != null && trip.tripStartDateTime!.isNotEmpty) {
                  final dateTime = DateTime.parse(trip.tripStartDateTime!);
                  formattedDate = DateFormat.yMd().format(dateTime);
                }
              } catch (e) {
                formattedDate = trip.tripStartDateTime ?? 'N/A';
              }

              final from = trip.sourceAddress?.placeAddress ?? 'N/A';
              final to = trip.destinationAddress?.placeAddress ?? 'N/A';
              final seats = trip.totalSeats;
              final bookedSeats = trip.bookedSeats;
              final bookingCount = trip.passengers?.length ?? 0;
              
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
                ref.invalidate(getUpcomingTripsForDriverProvider(_userId!));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
 