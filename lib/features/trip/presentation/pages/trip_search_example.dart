import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/core/providers/mutation_providers.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/trip/data/models/points.dart';

/// Example: Trip Search Screen
/// Demonstrates how to use searchMatchingRouteProvider to find available trips
/// 
/// Features:
/// - Input source and destination locations
/// - Search for matching trips with loading/error handling
/// - Display trip results with driver info, pricing, and available seats
/// - Navigate to booking confirmation
class TripSearchExample extends ConsumerStatefulWidget {
  const TripSearchExample({Key? key}) : super(key: key);

  @override
  ConsumerState<TripSearchExample> createState() => _TripSearchExampleState();
}

class _TripSearchExampleState extends ConsumerState<TripSearchExample> {
  // Demo coordinates (Berlin to Munich)
  final _sourceLat = 52.52;
  final _sourceLon = 13.405;
  final _destLat = 48.1351;
  final _destLon = 11.5820;
  final _sourceRadius = 5.0;
  final _destRadius = 5.0;
  final _requestedSeats = 2;
  final _rideStartTime = DateTime.now().toUtc().toIso8601String();
  final _effectiveUserId = 'user-123';

  @override
  Widget build(BuildContext context) {
    // Watch the search provider
    final searchAsync = ref.watch(
      searchMatchingRouteProvider(
        (
          sourceLat: _sourceLat,
          sourceLon: _sourceLon,
          sourceRadiusKm: _sourceRadius,
          destLat: _destLat,
          destLon: _destLon,
          destRadiusKm: _destRadius,
          requestedSeats: _requestedSeats,
          rideStartTime: _rideStartTime,
          effectiveUserId: _effectiveUserId,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Search Trips')),
      body: searchAsync.when(
        // ✅ Success: Display list of available trips
        data: (trips) => trips.isEmpty
            ? const Center(
                child: Text(
                  'No trips found.\nTry adjusting your search radius.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return TripCard(trip: trip);
                },
              ),

        // ⏳ Loading: Show spinner
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // ❌ Error: Show error message with retry button
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Refresh the provider
                  ref.refresh(
                    searchMatchingRouteProvider(
                      (
                        sourceLat: _sourceLat,
                        sourceLon: _sourceLon,
                        sourceRadiusKm: _sourceRadius,
                        destLat: _destLat,
                        destLon: _destLon,
                        destRadiusKm: _destRadius,
                        requestedSeats: _requestedSeats,
                        rideStartTime: _rideStartTime,
                        effectiveUserId: _effectiveUserId,
                      ),
                    ),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Trip Card Component
class TripCard extends ConsumerWidget {
  final Trip trip;

  const TripCard({Key? key, required this.trip}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text('${trip.sourceAddress.placeAddress} → ${trip.destinationAddress.placeAddress}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('🕒 ${trip.tripStartDateTime}'),
            Text('🚗 Vehicle: ${trip.vehicleNumber}'),
            Text('👤 Driver ID: ${trip.driverId}'),
            Text('💵 ₹${trip.estimatedFare.toStringAsFixed(2)} • ${trip.availableSeats} seats available'),
          ],
        ),
        onTap: () {
          // Navigate to booking confirmation screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingConfirmationExample(trip: trip),
            ),
          );
        },
      ),
    );
  }
}

/// Example: Booking Confirmation Screen
/// Demonstrates how to use joinTripProvider to book a trip
class BookingConfirmationExample extends ConsumerWidget {
  final Trip trip;

  const BookingConfirmationExample({Key? key, required this.trip})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the booking operation state
    final bookingAsync = ref.watch(joinTripProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      '📍 From',
                      trip.sourceAddress.placeAddress ?? 'Unknown',
                    ),
                    _buildDetailRow(
                      '📍 To',
                      trip.destinationAddress.placeAddress ?? 'Unknown',
                    ),
                    _buildDetailRow('🕒 Depart', trip.tripStartDateTime.toIso8601String()),
                    _buildDetailRow('🚗 Vehicle', trip.vehicleNumber ?? 'N/A'),
                    _buildDetailRow(
                      '💵 Estimated Fare',
                      '₹${trip.estimatedFare.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Booking Button with Loading/Error States
            SizedBox(
              width: double.infinity,
              child: bookingAsync.when(
                // ✅ Success: Show confirmation
                data: (response) {
                  if (response != null) {
                    return Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Booking Confirmed!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ride Status: ${response.statusLabel}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back to Search'),
                        ),
                      ],
                    );
                  }

                  // Initial state - show booking button
                  return ElevatedButton(
                    onPressed: () => _confirmBooking(context, ref),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Confirm Booking'),
                    ),
                  );
                },

                // ⏳ Loading: Show spinner
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),

                // ❌ Error: Show error message
                error: (error, stack) => Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Booking Failed',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Error: $error'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _confirmBooking(context, ref),
                      child: const Text('Retry Booking'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirm booking - called when user taps button
  void _confirmBooking(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(joinTripProvider.notifier);
    
    // Build the join request
    final joinRequest = JoinTripRequest(
      tripId: trip.tripId ?? 'unknown',
      passengerId: 'current-user-id', // TODO: Get from auth provider
      driverId: trip.driverId ?? '',
      pickupPoint: trip.sourceAddress,
      destinationPoint: trip.destinationAddress,
      rideStartTime: trip.tripStartDateTime.toIso8601String(),
      requestedSeats: 1,
    );

    // Trigger the booking operation
    notifier.joinTrip(joinRequest);
  }
}
