import 'package:flutter/material.dart';
import 'ride_detail_page.dart';
import 'package:carsharing/widgets/trip_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carsharing/services/places_service.dart';
import 'package:carsharing/services/trip_search_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';

class RideListPage extends ConsumerStatefulWidget {
  final String? searchQuery;

  const RideListPage({super.key, this.searchQuery});

  @override
  ConsumerState<RideListPage> createState() => _RideListPageState();
}

class _RideListPageState extends ConsumerState<RideListPage> {
  List<Trip> allRides = [];
  List<Trip> filteredRides = [];
  List<TripWithDistance> distanceFilteredRides = [];
  Set<String> favoriteRides = {}; // Store favorite ride IDs
  bool isLoading = true;
  int searchMode = 0; // 0: text, 1: pickup distance, 2: destination distance
  double selectedPickupRadius = 10.0;
  double selectedDestinationRadius = 10.0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pickupLocationController = TextEditingController();
  final TextEditingController _destinationLocationController = TextEditingController();

  double? _searchSourceLat;
  double? _searchSourceLon;
  double? _searchDestLat;
  double? _searchDestLon;

  String _getRideId(Trip ride) {
    return ride.tripId ?? '${ride.sourceAddress.placeAddress}-${ride.destinationAddress.placeAddress}';
  }

  Map<String, dynamic> _tripToMap(Trip trip) {
    return {
      'id': trip.tripId,
      'tripId': trip.tripId,
      'driverId': trip.driverId,
      'vehicleNumber': trip.vehicleNumber,
      'from': trip.sourceAddress.placeAddress,
      'to': trip.destinationAddress.placeAddress,
      'fromAddress': trip.sourceAddress.placeAddress,
      'toAddress': trip.destinationAddress.placeAddress,
      'fromLatitude': trip.sourceAddress.latitude,
      'fromLongitude': trip.sourceAddress.longitude,
      'toLatitude': trip.destinationAddress.latitude,
      'toLongitude': trip.destinationAddress.longitude,
      'sourceLatitude': trip.sourceAddress.latitude,
      'sourceLongitude': trip.sourceAddress.longitude,
      'destinationLatitude': trip.destinationAddress.latitude,
      'destinationLongitude': trip.destinationAddress.longitude,
      'seats': trip.availableSeats,
      'offeredSeats': trip.offeredSeat,
      'availableSeats': trip.availableSeats,
      'price': trip.estimatedFare,
      'date': trip.tripStartDateTime,
      'tripStartDateTime': trip.tripStartDateTime,
      'tripStatus': trip.tripStatus,
      'routeDistance': trip.routeDistance,
      'routeDuration': trip.routeDuration,
    };
  }

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery ?? '';
    // Load initial trips if search query is provided
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      _filterRides();
    }
  }

  Future<void> loadRides() async {
    // For now, we need coordinates to search. This method will be called
    // after user sets pickup/destination locations
    if (_searchSourceLat == null || _searchSourceLon == null ||
        _searchDestLat == null || _searchDestLon == null) {
      setState(() {
        allRides = [];
        filteredRides = [];
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final tokenStorage = ref.read(secureStorageProvider);
      final userId = await tokenStorage.getUserId() ?? user?.uid;
      if (userId == null || userId.isEmpty) {
        throw Exception('Missing user id for matching-route search');
      }
      final rideStartTime = DateTime.now().toUtc().toIso8601String();
      const requestedSeats = 1;
      final searchResults = await ref.read(searchMatchingRouteProvider((
        sourceLat: _searchSourceLat!,
        sourceLon: _searchSourceLon!,
        sourceRadiusKm: selectedPickupRadius,
        destLat: _searchDestLat!,
        destLon: _searchDestLon!,
        destRadiusKm: selectedDestinationRadius,
        requestedSeats: requestedSeats,
        rideStartTime: rideStartTime,
        effectiveUserId: userId,
      )).future);

      setState(() {
        allRides = searchResults.cast<Trip>();
        _filterRides();
        isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print("Error loading rides from API: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching for trips: $e')),
      );
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
          final start = (ride.sourceAddress.placeAddress ?? '').toLowerCase();
          final end = (ride.destinationAddress.placeAddress ?? '').toLowerCase();
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

      setState(() {
        _searchSourceLat = userLocation.latitude;
        _searchSourceLon = userLocation.longitude;
      });

      // If we also have destination, trigger full search
      if (_searchDestLat != null && _searchDestLon != null) {
        await loadRides();
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please also enter a destination location')),
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

      setState(() {
        _searchDestLat = destLocation.latitude;
        _searchDestLon = destLocation.longitude;
      });

      // If we also have source, trigger full search
      if (_searchSourceLat != null && _searchSourceLon != null) {
        await loadRides();
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please also enter a pickup location')),
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
                                ride: _tripToMap(ride),
                                isFavorite: isFavorite,
                                onFavoriteToggle: () {}, // Favorites disabled for REST
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RideDetailPage(ride: _tripToMap(ride)),
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
                              // Distance-based local filtering disabled - REST API handles distance filtering
                              return const SizedBox.shrink();
                            },
                          )),
          ),
        ],
      ),
    );
  }
}