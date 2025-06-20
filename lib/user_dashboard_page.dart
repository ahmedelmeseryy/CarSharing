import 'package:flutter/material.dart';
import 'package:carsharing/pages/user/tabs/available_trips_tab.dart';
import 'package:carsharing/pages/user/trip_details_page.dart';
import 'package:carsharing/main.dart'; // For ProfilePage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:carsharing/ride_detail_page.dart';
import 'package:intl/intl.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  _UserDashboardPageState createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int _selectedIndex = 0;
  String _searchQuery = '';

  Widget _getAvailableTripsWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips'),
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

class BookedTripsPage extends StatefulWidget {
  const BookedTripsPage({super.key});

  @override
  State<BookedTripsPage> createState() => _BookedTripsPageState();
}

class _BookedTripsPageState extends State<BookedTripsPage> {
  final user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _getBookedTripsStream() {
    if (user == null) {
      print('User not logged in for bookings');
      return Stream.empty();
    }
    print('Loading bookings for user: ${user!.uid}');
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booked Trips'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getBookedTripsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have no booked trips yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final bookingData = booking.data() as Map<String, dynamic>;
              
              String formattedDate = 'N/A';
              if (bookingData['createdAt'] is Timestamp) {
                formattedDate = DateFormat.yMd().format((bookingData['createdAt'] as Timestamp).toDate());
              }

              String tripDate = 'N/A';
              if (bookingData['tripDate'] is Timestamp) {
                tripDate = DateFormat.yMd().format((bookingData['tripDate'] as Timestamp).toDate());
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, size: 30, color: Colors.blue),
                  ),
                  title: Text(
                    '${bookingData['tripFrom']} to ${bookingData['tripTo']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booked: $formattedDate'),
                      Text('Trip Date: $tripDate'),
                      Text('Seats: ${bookingData['seats']} - Total: €${bookingData['totalPrice']}'),
                      Text('Payment: ${bookingData['paymentMethod']}'),
                    ],
                  ),
                  trailing: _buildStatusChip(bookingData['status'] ?? 'pending'),
                  isThreeLine: true,
                  onTap: () => _showBookingDetails(bookingData),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        text = 'Confirmed';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _showBookingDetails(Map<String, dynamic> bookingData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip: ${bookingData['tripFrom']} to ${bookingData['tripTo']}'),
            Text('Seats: ${bookingData['seats']}'),
            Text('Total Price: €${bookingData['totalPrice']}'),
            Text('Payment Method: ${bookingData['paymentMethod'] ?? 'N/A'}'),
            Text('Status: ${bookingData['status'] ?? 'pending'}'),
            if (bookingData['createdAt'] is Timestamp)
              Text('Booked: ${DateFormat.yMd().add_jm().format((bookingData['createdAt'] as Timestamp).toDate())}'),
            if (bookingData['tripDate'] is Timestamp)
              Text('Trip Date: ${DateFormat.yMd().add_jm().format((bookingData['tripDate'] as Timestamp).toDate())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class FavoriteTripsPage extends StatefulWidget {
  const FavoriteTripsPage({super.key});

  @override
  _FavoriteTripsPageState createState() => _FavoriteTripsPageState();
}

class _FavoriteTripsPageState extends State<FavoriteTripsPage> {
  final user = FirebaseAuth.instance.currentUser;

  Stream<List<dynamic>> _getFavoriteTripsStream() {
    if (user == null) {
      return Stream.value([]);
    }

    final userDocStream = FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots();

    return userDocStream.asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data()!['favorite_trips'] == null) {
        return [];
      }
      final List<String> favoriteTripIds = List<String>.from(userDoc.data()!['favorite_trips']);
      if (favoriteTripIds.isEmpty) {
        return [];
      }
      
      // Fetch from Firestore trips collection
      final firestoreTripsSnapshot = await FirebaseFirestore.instance.collection('trips').get();
      final List<dynamic> firestoreTrips = firestoreTripsSnapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
      
      return firestoreTrips.where((trip) {
        final tripId = trip['id'] ?? '${trip['from']}-${trip['to']}';
        return favoriteTripIds.contains(tripId);
      }).toList();
    });
  }
  
  String _getTripId(dynamic trip) {
    return trip['id'] ?? '${trip['from']}-${trip['to']}';
  }
  
  void _toggleFavorite(String tripId) {
    if (user == null) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    userRef.update({
      'favorite_trips': FieldValue.arrayRemove([tripId])
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Trips'),
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _getFavoriteTripsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have no favorite trips yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final favoriteTrips = snapshot.data!;

          return ListView.builder(
            itemCount: favoriteTrips.length,
            itemBuilder: (context, index) {
              final trip = favoriteTrips[index];
              final tripId = _getTripId(trip);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${trip['from']} to ${trip['to']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('€${trip['price']} - ${trip['date']}'),
                      Text('Driver: ${trip['driverName'] ?? 'Unknown'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => _toggleFavorite(tripId),
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () {
                    // Navigate to trip details page using the trip ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripDetailsPage(tripId: trip['id'] ?? ''),
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