import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'ride_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideListPage extends StatefulWidget {
  final String? searchQuery;
  
  const RideListPage({super.key, this.searchQuery});

  @override
  State<RideListPage> createState() => _RideListPageState();
}

class _RideListPageState extends State<RideListPage> {
  List<dynamic> allRides = [];
  List<dynamic> filteredRides = [];
  Set<String> favoriteRides = {}; // Store favorite ride IDs
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery ?? '';
    loadRides();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    // TODO: Load favorites from Firebase
    // For now, using dummy data
    setState(() {
      favoriteRides = {'Berlin-München', 'Frankfurt-Stuttgart'};
    });
  }

  void _toggleFavorite(String rideId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add favorites.')),
      );
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    setState(() {
      if (favoriteRides.contains(rideId)) {
        favoriteRides.remove(rideId);
        userRef.update({
          'favorite_trips': FieldValue.arrayRemove([rideId])
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
      } else {
        favoriteRides.add(rideId);
        userRef.update({
          'favorite_trips': FieldValue.arrayUnion([rideId])
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites')),
        );
      }
    });
  }

  String _getRideId(dynamic ride) {
    // Use Firestore document ID if available, otherwise construct one
    return ride['id'] ?? '${ride['start']}-${ride['end']}';
  }

  Future<void> loadRides() async {
    setState(() {
      isLoading = true;
    });
    try {
      final firestoreRidesSnapshot = await FirebaseFirestore.instance.collection('rides').get();
      final List<dynamic> firestoreRides = firestoreRidesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        allRides = firestoreRides;
        _filterRides();
        isLoading = false;
      });
    } catch (e) {
      // Handle error, maybe show a message to the user
      print("Error loading rides from Firestore: $e");
      setState(() {
        allRides = [];
        filteredRides = [];
        isLoading = false;
      });
    }
  }

  void _filterRides() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        filteredRides = allRides;
      });
    } else {
      setState(() {
        filteredRides = allRides.where((ride) {
          final start = ride['start'].toString().toLowerCase();
          final end = ride['end'].toString().toLowerCase();
          return start.contains(query) || end.contains(query);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by city...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterRides();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _filterRides(),
            ),
          ),
          // Results count
          if (filteredRides.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filteredRides.length} ride${filteredRides.length == 1 ? '' : 's'} found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Rides list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRides.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No rides found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching for a different city',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: filteredRides.length,
                        itemBuilder: (context, index) {
                          final ride = filteredRides[index];
                          final rideId = _getRideId(ride);
                          final isFavorite = favoriteRides.contains(rideId);
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.person, size: 30, color: Colors.blue),
                              ),
                              title: Text(
                                '${ride['start']} to ${ride['end']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${ride['date']} at ${ride['time']}\nDriver: ${ride['driver']} - €${ride['price']}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () => _toggleFavorite(rideId),
                                  ),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                              isThreeLine: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RideDetailPage(ride: ride),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 