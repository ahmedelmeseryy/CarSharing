import 'package:flutter/material.dart';
import 'ride_detail_page.dart';
import 'package:carsharing/widgets/trip_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carsharing/services/places_service.dart';
import 'package:carsharing/services/trip_search_service.dart';

class RideListPage extends StatefulWidget {
  final String? searchQuery;

  const RideListPage({super.key, this.searchQuery});

  @override
  State<RideListPage> createState() => _RideListPageState();
}

class _RideListPageState extends State<RideListPage> {
  List<dynamic> allRides = [];
  List<dynamic> filteredRides = [];
  List<TripWithDistance> distanceFilteredRides = [];
  Set<String> favoriteRides = {}; // Store favorite ride IDs
  bool isLoading = true;
  int searchMode = 0; // 0: text, 1: pickup distance, 2: destination distance
  double selectedPickupRadius = 10.0;
  double selectedDestinationRadius = 10.0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pickupLocationController = TextEditingController();
  final TextEditingController _destinationLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery ?? '';
    loadRides();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final favoriteTripIds = userDoc.data()?['favorite_trips'] as List<dynamic>?;
        if (favoriteTripIds != null) {
          setState(() {
            favoriteRides = Set<String>.from(
              favoriteTripIds.map((id) => id.toString())
            );
          });
        }
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
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
      // ignore: avoid_print
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
        searchMode = 0;
      });
    } else {
      setState(() {
        filteredRides = allRides.where((ride) {
          final start = ride['start'].toString().toLowerCase();
          final end = ride['end'].toString().toLowerCase();
          return start.contains(query) || end.contains(query);
        }).toList();
        searchMode = 0;
      });
    }
  }

  /// Perform distance-based search by pickup location
  Future<void> _searchByPickupDistance() async {
    final pickupAddress = _pickupLocationController.text.trim();
    if (pickupAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a pickup location')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userLocation = await PlacesService.geocodeAddress(pickupAddress);
      
      if (userLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find location. Please try a different address.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final results = TripSearchService.filterAndRankByDistance(
        allRides,
        userLocation.latitude,
        userLocation.longitude,
        radiusKm: selectedPickupRadius,
      );

      setState(() {
        distanceFilteredRides = results;
        searchMode = 1;
        isLoading = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No trips found within ${selectedPickupRadius.toStringAsFixed(1)} km')),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('[RIDE_LIST] Pickup distance search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error searching by distance. Please try again.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Perform distance-based search by destination
  Future<void> _searchByDestinationDistance() async {
    final destAddress = _destinationLocationController.text.trim();
    if (destAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination location')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final destLocation = await PlacesService.geocodeAddress(destAddress);
      
      if (destLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find destination. Please try a different address.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final results = TripSearchService.filterAndRankByDestinationDistance(
        allRides,
        destLocation.latitude,
        destLocation.longitude,
        radiusKm: selectedDestinationRadius,
      );

      setState(() {
        distanceFilteredRides = results;
        searchMode = 2;
        isLoading = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No trips found within ${selectedDestinationRadius.toStringAsFixed(1)} km of destination')),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('[RIDE_LIST] Destination distance search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error searching by distance. Please try again.')),
      );
      setState(() {
        isLoading = false;
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
          // Tabs for search mode selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        searchMode = 0;
                        distanceFilteredRides.clear();
                      });
                    },
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Text'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: searchMode == 0
                          ? Colors.blue
                          : Colors.grey[300],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        searchMode = 1;
                      });
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Pickup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: searchMode == 1
                          ? Colors.blue
                          : Colors.grey[300],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        searchMode = 2;
                      });
                    },
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Dropoff'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: searchMode == 2
                          ? Colors.blue
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Text Search UI
          if (searchMode == 0) ...[
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
            // Results count for text search
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
          ] else if (searchMode == 1) ...[
            // Pickup Distance Search UI
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _pickupLocationController,
                    decoration: InputDecoration(
                      hintText: 'Enter pickup location (address or city)',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Radius: ${selectedPickupRadius.toStringAsFixed(1)} km',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: selectedPickupRadius,
                        min: 2.0,
                        max: 20.0,
                        divisions: 9,
                        onChanged: (value) {
                          setState(() {
                            selectedPickupRadius = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _searchByPickupDistance,
                      icon: const Icon(Icons.search),
                      label: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Search by Pickup'),
                    ),
                  ),
                ],
              ),
            ),
            // Results count for pickup distance search
            if (distanceFilteredRides.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${distanceFilteredRides.length} ride${distanceFilteredRides.length == 1 ? '' : 's'} found within ${selectedPickupRadius.toStringAsFixed(1)} km',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ] else if (searchMode == 2) ...[
            // Destination Distance Search UI
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _destinationLocationController,
                    decoration: InputDecoration(
                      hintText: 'Enter destination location (address or city)',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Radius: ${selectedDestinationRadius.toStringAsFixed(1)} km',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: selectedDestinationRadius,
                        min: 2.0,
                        max: 20.0,
                        divisions: 9,
                        onChanged: (value) {
                          setState(() {
                            selectedDestinationRadius = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _searchByDestinationDistance,
                      icon: const Icon(Icons.search),
                      label: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Search by Dropoff'),
                    ),
                  ),
                ],
              ),
            ),
            // Results count for destination distance search
            if (distanceFilteredRides.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${distanceFilteredRides.length} ride${distanceFilteredRides.length == 1 ? '' : 's'} found within ${selectedDestinationRadius.toStringAsFixed(1)} km of destination',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          // Rides list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchMode == 0
                    ? (filteredRides.isEmpty
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

                              return TripCard(
                                ride: Map<String, dynamic>.from(ride),
                                isFavorite: isFavorite,
                                onFavoriteToggle: () => _toggleFavorite(rideId),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RideDetailPage(ride: ride),
                                    ),
                                  );
                                },
                              );
                            },
                          ))
                    : (distanceFilteredRides.isEmpty
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
                                  'No trips found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  searchMode == 1
                                      ? 'Try a different pickup location or increase the search radius'
                                      : 'Try a different destination or increase the search radius',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            itemCount: distanceFilteredRides.length,
                            itemBuilder: (context, index) {
                              final tripWithDistance = distanceFilteredRides[index];
                              final ride = tripWithDistance.trip;
                              final rideId = _getRideId(ride);
                              final isFavorite = favoriteRides.contains(rideId);

                              return Stack(
                                children: [
                                  TripCard(
                                    ride: Map<String, dynamic>.from(ride),
                                    isFavorite: isFavorite,
                                    onFavoriteToggle: () => _toggleFavorite(rideId),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RideDetailPage(ride: ride),
                                        ),
                                      );
                                    },
                                  ),
                                  // Distance badge
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        TripSearchService.formatDistance(
                                          tripWithDistance.distanceKm,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )),
          ),
        ],
      ),
    );
  }
}