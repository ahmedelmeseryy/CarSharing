import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/booking/presentation/trip_booking_detail_page.dart';

class TripSearchResultsPage extends ConsumerWidget {
  final List<Trip> trips;
  final String searchFrom;
  final String searchTo;

  const TripSearchResultsPage({
    super.key,
    required this.trips,
    required this.searchFrom,
    required this.searchTo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Search Results'),
            Text(
              '$searchFrom → $searchTo',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: trips.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No matching trips found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your search criteria',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Found ${trips.length} matching trip${trips.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildTripCard(context, ref, trips[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTripCard(BuildContext context, WidgetRef ref, Trip trip) {
    final price = trip.estimatedFare.toStringAsFixed(2);
    final seats = trip.freeSeats;
    final formattedDate =
        DateFormat.yMd().add_jm().format(trip.tripStartDateTime.toLocal());

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '€$price',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text('Seats: $seats'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              trip.sourceAddress.placeAddress ?? 'Unknown origin',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.flag, size: 16, color: Colors.red),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              trip.destinationAddress.placeAddress ?? 'Unknown destination',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDriverInfo(trip.driverId ?? ''),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Trip: ${trip.tripId ?? 'N/A'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (trip.tripId == null || trip.tripId!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip details are missing. Please try another trip.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripBookingDetailPage(trip: trip),
                    ),
                  );
                },
                child: const Text('Book Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo(String driverId) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Driver ID: $driverId',
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
