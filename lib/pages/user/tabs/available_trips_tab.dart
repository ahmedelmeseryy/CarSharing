import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/core/providers/mutation_providers.dart';
import 'package:carsharing/core/storage/secure_storage.dart';
import 'package:carsharing/services/location_service.dart';

class AvailableTripsTab extends ConsumerStatefulWidget {
  final String searchQuery;
  const AvailableTripsTab({super.key, required this.searchQuery});

  @override
  ConsumerState<AvailableTripsTab> createState() => _AvailableTripsTabState();
}

class _AvailableTripsTabState extends ConsumerState<AvailableTripsTab> {
  double? _lat;
  double? _lon;
  bool _locationChecked = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() {
        _lat = pos?.latitude ?? 52.52; // fallback to Berlin
        _lon = pos?.longitude ?? 13.405;
        _locationChecked = true;
      });
    } catch (_) {
      // If location services crash (e.g., missing Play Services), fall back to a safe default.
      setState(() {
        _lat = 52.52;
        _lon = 13.405;
        _locationChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we haven't checked location yet, show loader
    if (!_locationChecked) {
      return const Center(child: CircularProgressIndicator());
    }

    // If location unavailable, show prompt
    if (_lat == null || _lon == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Location unavailable. Enable location services to find nearby trips.'),
            ],
          ),
        ),
      );
    }

    final tripsAsync = ref.watch(
      searchNearSourceProvider((
        lat: _lat!,
        lon: _lon!,
        radiusKm: 10.0,
      )),
    );

    final tokenStorage = ref.read(secureStorageProvider);
    final joinNotifier = ref.read(joinTripProvider.notifier);

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (data) {
        final trips = (data as List).cast<Trip>();

        // Apply text filter to addresses
        List<Trip> filtered = trips;
        if (widget.searchQuery.isNotEmpty) {
          final q = widget.searchQuery.toLowerCase();
          filtered = trips.where((t) {
            final from = t.sourceAddress.placeAddress?.toLowerCase() ?? '';
            final to = t.destinationAddress.placeAddress?.toLowerCase() ?? '';
            return from.contains(q) || to.contains(q);
          }).toList();
        }

        if (filtered.isEmpty) {
          return const Center(child: Text('No trips found for your search query.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final trip = filtered[index];
            final dateStr = DateFormat.yMd().add_Hm().format(trip.tripStartDateTime.toLocal());
            final price = trip.estimatedFare.toStringAsFixed(2);
            final seats = trip.availableSeats;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.directions_car, color: Colors.blue),
                ),
                title: Text(
                  '${trip.sourceAddress.placeAddress ?? 'Unknown'} → ${trip.destinationAddress.placeAddress ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Date: $dateStr | ₹$price | $seats seat(s)',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (ctx) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trip Details',
                                style: Theme.of(ctx).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text('From: ${trip.sourceAddress.placeAddress ?? 'Unknown'}'),
                              Text('To: ${trip.destinationAddress.placeAddress ?? 'Unknown'}'),
                              Text('Vehicle: ${trip.vehicleNumber ?? 'N/A'}'),
                              Text('Driver ID: ${trip.driverId ?? 'N/A'}'),
                              Text('Date: $dateStr'),
                              Text('Estimated Fare: ₹$price'),
                              Text('Available Seats: $seats'),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Close'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final passengerId = await tokenStorage.getUserId();
                                      if (passengerId == null || passengerId.isEmpty) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please log in to book this trip.')),
                                          );
                                        }
                                        return;
                                      }

                                      final request = JoinTripRequest(
                                        tripId: trip.tripId ?? '',
                                        passengerId: passengerId,
                                        driverId: trip.driverId ?? '',
                                        pickupPoint: trip.sourceAddress,
                                        destinationPoint: trip.destinationAddress,
                                        rideStartTime: trip.tripStartDateTime.toUtc().toIso8601String(),
                                        requestedSeats: 1,
                                      );

                                      await joinNotifier.joinTrip(request);
                                      final state = ref.read(joinTripProvider);
                                      state.when(
                                        data: (booking) {
                                          Navigator.pop(ctx);
                                          if (booking != null && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Trip booked successfully!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        },
                                        error: (error, stack) {
                                          Navigator.pop(ctx);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed to book trip: $error')),
                                            );
                                          }
                                        },
                                        loading: () {},
                                      );
                                    },
                                    child: const Text('Book'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
