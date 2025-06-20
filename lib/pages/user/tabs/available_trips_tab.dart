import 'package:carsharing/pages/user/trip_details_page.dart';
import 'package:carsharing/pages/user/driver_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AvailableTripsTab extends StatefulWidget {
  final String searchQuery;
  const AvailableTripsTab({super.key, required this.searchQuery});

  @override
  State<AvailableTripsTab> createState() => _AvailableTripsTabState();
}

class _AvailableTripsTabState extends State<AvailableTripsTab> {
  Set<String> favoriteTrips = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (userDoc.exists && userDoc.data()!['favorite_trips'] != null) {
      final List<String> favorites = List<String>.from(userDoc.data()!['favorite_trips']);
      setState(() {
        favoriteTrips = favorites.toSet();
      });
    }
  }

  void _toggleFavorite(String tripId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add favorites.')),
      );
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    setState(() {
      if (favoriteTrips.contains(tripId)) {
        favoriteTrips.remove(tripId);
        userRef.update({
          'favorite_trips': FieldValue.arrayRemove([tripId])
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
      } else {
        favoriteTrips.add(tripId);
        userRef.update({
          'favorite_trips': FieldValue.arrayUnion([tripId])
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No trips available.'));
        }

        var trips = snapshot.data!.docs;

        if (widget.searchQuery.isNotEmpty) {
          trips = trips.where((trip) {
            final data = trip.data() as Map<String, dynamic>;
            final from = data['from'].toString().toLowerCase();
            final to = data['to'].toString().toLowerCase();
            final searchLower = widget.searchQuery.toLowerCase();
            return from.contains(searchLower) || to.contains(searchLower);
          }).toList();
        }

        if (trips.isEmpty) {
          return const Center(
              child: Text('No trips found for your search query.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            final tripData = trip.data() as Map<String, dynamic>;
            final tripId = trip.id;
            final price = tripData['price']?.toStringAsFixed(2) ?? 'N/A';
            final seats = tripData['seats']?.toString() ?? 'N/A';
            final isFavorite = favoriteTrips.contains(tripId);

            String formattedDate = 'N/A';
            if (tripData['date'] is Timestamp) {
              formattedDate =
                  DateFormat.yMd().format((tripData['date'] as Timestamp).toDate());
            }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverProfilePage(
                          driverId: tripData['driverId'] ?? '',
                          driverName: tripData['driverName'] ?? 'Unknown Driver',
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, size: 30, color: Colors.blue),
                  ),
                ),
                title: Text(
                  '${tripData['from']} to ${tripData['to']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: $formattedDate'),
                    Text('Seats: $seats'),
                    Text('Driver: ${tripData['driverName'] ?? 'Unknown'}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€$price',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text('per seat', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(tripId),
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TripDetailsPage(tripId: trip.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
