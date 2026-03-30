import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/core/providers/mutation_providers.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/points.dart';

/// Example: Driver Offer Trip Screen
/// Demonstrates how to use offerTripProvider to create a new trip offering
/// 
/// Features:
/// - Driver inputs trip details (source, destination, vehicle, time, seats)
/// - Submits offer with loading/error handling
/// - Shows confirmation with earnings estimate
class OfferTripExample extends ConsumerStatefulWidget {
  const OfferTripExample({Key? key}) : super(key: key);

  @override
  ConsumerState<OfferTripExample> createState() => _OfferTripExampleState();
}

class _OfferTripExampleState extends ConsumerState<OfferTripExample> {
  late TextEditingController vehicleController;
  late TextEditingController seatsController;

  // Demo coordinates and data
  final _driverId = 'driver-123';
  final _sourceLat = 52.52;
  final _sourceLon = 13.405;
  final _destLat = 48.1351;
  final _destLon = 11.5820;

  @override
  void initState() {
    super.initState();
    vehicleController = TextEditingController(text: 'ABC-1234');
    seatsController = TextEditingController(text: '4');
  }

  @override
  void dispose() {
    vehicleController.dispose();
    seatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the offer trip mutation
    final offerAsync = ref.watch(offerTripProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Offer a Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Details Form
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

                    // Vehicle Number
                    TextField(
                      controller: vehicleController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Number',
                        hintText: 'e.g., ABC-1234',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Available Seats
                    TextField(
                      controller: seatsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Available Seats',
                        hintText: '1-7',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Route Display (Read-only)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📍 From: Berlin'),
                          const SizedBox(height: 8),
                          const Text('📍 To: Munich'),
                          const SizedBox(height: 8),
                          const Text('🕒 Depart: 2024-01-15 10:00 AM'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Offer Button with States
            SizedBox(
              width: double.infinity,
              child: offerAsync.when(
                // ✅ Success: Show confirmation
                data: (response) {
                  if (response != null) {
                    return Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Trip Offer Created!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  'Trip ID',
                                  response.tripId ?? 'N/A',
                                ),
                                _buildDetailRow(
                                  'Available Seats',
                                  '${response.availableSeats}',
                                ),
                                _buildDetailRow(
                                  'Route Distance',
                                  '${response.routeDistanceInKm?.toStringAsFixed(2) ?? 'N/A'} km',
                                ),
                                _buildDetailRow(
                                  'Est. Duration',
                                  '${response.routeDurationInMinutes ?? 0} mins',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(offerTripProvider.notifier).reset();
                            Navigator.pop(context);
                          },
                          child: const Text('Back'),
                        ),
                      ],
                    );
                  }

                  // Initial state
                  return ElevatedButton(
                    onPressed: _submitOffer,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Offer Trip'),
                    ),
                  );
                },

                // ⏳ Loading
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),

                // ❌ Error
                error: (error, stack) => Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitOffer,
                      child: const Text('Retry'),
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

  /// Submit the offer
  void _submitOffer() {
    final notifier = ref.read(offerTripProvider.notifier);
    final seats = int.tryParse(seatsController.text) ?? 4;

    final offerRequest = OfferRideRequest(
      driverId: _driverId,
      vehicleNumber: vehicleController.text,
      sourceAddress: const Points(
        latitude: 52.52,
        longitude: 13.405,
        placeAddress: 'Berlin, Germany',
      ),
      destinationAddress: const Points(
        latitude: 48.1351,
        longitude: 11.5820,
        placeAddress: 'Munich, Germany',
      ),
      tripStartDateTime: DateTime.parse('2024-01-15T10:00:00Z'),
      totalSeats: seats,
    );

    notifier.offerTrip(offerRequest);
  }

  /// Helper to build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Example: Driver's Upcoming Trips Screen
/// Shows all upcoming trips for the driver with bookings
class DriverUpcomingTripsExample extends ConsumerWidget {
  final String driverId;

  const DriverUpcomingTripsExample({
    Key? key,
    required this.driverId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch driver's upcoming trips
    final tripsAsync = ref.watch(
      getUpcomingTripsForDriverProvider(driverId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('My Upcoming Trips')),
      body: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return const Center(
              child: Text('No upcoming trips.\nOffer a trip to get started!'),
            );
          }

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text(
                    '${trip.sourceAddress.placeAddress} → ${trip.destinationAddress.placeAddress}',
                  ),
                  subtitle: Text('🕒 ${trip.tripStartDateTime}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Trip ID',
                            trip.tripId ?? 'unknown',
                          ),
                          _buildDetailRow(
                            'Vehicle',
                            trip.vehicleNumber,
                          ),
                          _buildDetailRow(
                            'Available / Total Seats',
                            '${trip.availableSeats} / ${trip.totalSeats}',
                          ),
                          _buildDetailRow(
                            'Est. Earnings',
                            '₹${trip.estimatedFare.toStringAsFixed(2)}',
                          ),
                          if (trip.joinedRidersId?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Passengers:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...trip.joinedRidersId!.map(
                              (id) => Text('• $id'),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cancel trip functionality'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Cancel Trip'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
}
