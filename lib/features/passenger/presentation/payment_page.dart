import 'package:carsharing/features/booking/presentation/booking_confirmation_page.dart';
import 'package:carsharing/core/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/mutation_providers.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/features/trip/data/models/points.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';

class PaymentPage extends ConsumerWidget {
  final Map<String, dynamic> tripData;
  final String tripId;
  final int selectedSeats;

  const PaymentPage({
    super.key,
    required this.tripData,
    required this.tripId,
    required this.selectedSeats,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricePerSeat = tripData['price'] as double;
    final totalPrice = pricePerSeat * selectedSeats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm & Pay'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Booking Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSummaryRow('Trip', '${tripData['from']} to ${tripData['to']}'),
                    _buildSummaryRow('Seats', '$selectedSeats'),
                    _buildSummaryRow('Price per Seat', '€${pricePerSeat.toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    _buildSummaryRow('Total Price', '€${totalPrice.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.credit_card),
              label: const Text('Pay with Card'),
              onPressed: () {
                // In a real app, navigate to a card payment screen.
                // For now, we'll treat it as a successful booking.
                _processBooking(context, ref, 'Card', totalPrice);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.money),
              label: const Text('Pay with Cash'),
              onPressed: () {
                 _processBooking(context, ref, 'Cash', totalPrice);
              },
               style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            value,
             style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processBooking(BuildContext context, WidgetRef ref, String paymentMethod, double totalPrice) async {
    final userId = await TokenStorage().getUserId();
    if (!context.mounted) return;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to book a trip.')),
      );
      return;
    }

    try {
      // Extract trip details from tripData
      final driverId = tripData['driverId'] ?? '';
      final sourceLat = tripData['fromLatitude'] ?? tripData['sourceLatitude'] ?? 0.0;
      final sourceLon = tripData['fromLongitude'] ?? tripData['sourceLongitude'] ?? 0.0;
      final destLat = tripData['toLatitude'] ?? tripData['destinationLatitude'] ?? 0.0;
      final destLon = tripData['toLongitude'] ?? tripData['destinationLongitude'] ?? 0.0;
      final fromAddress = tripData['from'] ?? tripData['fromAddress'] ?? '';
      final toAddress = tripData['to'] ?? tripData['toAddress'] ?? '';
      final tripStartTime = tripData['date']?.toString() ?? DateTime.now().toUtc().toIso8601String();

      final request = JoinTripRequest(
        tripId: tripId,
        passengerId: userId,
        driverId: driverId,
        pickupPoint: Points(
          latitude: sourceLat is double ? sourceLat : (sourceLat as num).toDouble(),
          longitude: sourceLon is double ? sourceLon : (sourceLon as num).toDouble(),
          placeAddress: fromAddress,
        ),
        destinationPoint: Points(
          latitude: destLat is double ? destLat : (destLat as num).toDouble(),
          longitude: destLon is double ? destLon : (destLon as num).toDouble(),
          placeAddress: toAddress,
        ),
        rideStartTime: tripStartTime,
        requestedSeats: selectedSeats,
      );

      final notifier = ref.read(joinTripProvider.notifier);
      await notifier.joinTrip(request);

      final state = ref.read(joinTripProvider);
      state.when(
        data: (booking) {
          if (booking != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip booked successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            notifier.reset();
            final double price = (tripData['price'] as num?)?.toDouble() ?? 0.0;
            final trip = Trip(
              tripId: tripId,
              tripStatus: 'available',
              vehicleNumber: '',
              driverId: tripData['driverId'] ?? '',
              sourceAddress: Points(
                latitude: (tripData['fromLatitude'] ?? tripData['sourceLatitude'] ?? 0.0) is num
                    ? ((tripData['fromLatitude'] ?? tripData['sourceLatitude']) as num).toDouble()
                    : 0.0,
                longitude: (tripData['fromLongitude'] ?? tripData['sourceLongitude'] ?? 0.0) is num
                    ? ((tripData['fromLongitude'] ?? tripData['sourceLongitude']) as num).toDouble()
                    : 0.0,
                placeAddress: tripData['from'] ?? tripData['fromAddress'] ?? '',
              ),
              destinationAddress: Points(
                latitude: (tripData['toLatitude'] ?? tripData['destinationLatitude'] ?? 0.0) is num
                    ? ((tripData['toLatitude'] ?? tripData['destinationLatitude']) as num).toDouble()
                    : 0.0,
                longitude: (tripData['toLongitude'] ?? tripData['destinationLongitude'] ?? 0.0) is num
                    ? ((tripData['toLongitude'] ?? tripData['destinationLongitude']) as num).toDouble()
                    : 0.0,
                placeAddress: tripData['to'] ?? tripData['toAddress'] ?? '',
              ),
              totalSeats: selectedSeats,
              bookedSeats: 0,
              tripStartDateTime: tripData['date'] != null
                  ? DateTime.tryParse(tripData['date'].toString()) ?? DateTime.now()
                  : DateTime.now(),
              pricePerSeat: price,
              routeDistance: 1000.0,
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => BookingConfirmationPage(
                  trip: trip,
                  selectedSeats: selectedSeats,
                  paymentMethod: paymentMethod,
                  booking: booking,
                ),
              ),
              (Route<dynamic> route) => route.isFirst,
            );
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to book trip: $error')),
          );
        },
        loading: () {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book trip: $e')),
      );
    }
  }
} 