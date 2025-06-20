import 'package:carsharing/pages/user/booking_confirmation_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                _processBooking(context, 'Card', totalPrice);
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
                 _processBooking(context, 'Cash', totalPrice);
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

  Future<void> _processBooking(BuildContext context, String paymentMethod, double totalPrice) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to book a trip.')),
      );
      return;
    }

    // Debug: Print tripData to see what fields are available
    print('TripData received:');
    tripData.forEach((key, value) {
      print('  $key: $value');
    });

    final tripRef = FirebaseFirestore.instance.collection('trips').doc(tripId);
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final tripSnapshot = await transaction.get(tripRef);

        if (!tripSnapshot.exists) {
          throw Exception("Trip does not exist!");
        }

        final currentSeats = tripSnapshot.data()!['seats'] as int;
        if (currentSeats < selectedSeats) {
          throw Exception("Not enough seats available.");
        }

        final newSeatCount = currentSeats - selectedSeats;
        transaction.update(tripRef, {'seats': newSeatCount});

        // Get the actual trip data from Firestore to ensure we have the correct field names
        final actualTripData = tripSnapshot.data()!;
        
        // Get user data from Firestore to get the actual name
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data();
        final passengerName = userData != null 
            ? '${userData['name'] ?? ''} ${userData['surname'] ?? ''}'.trim()
            : 'Unknown Passenger';
        
        transaction.set(bookingRef, {
          'tripId': tripId,
          'userId': user.uid,
          'driverId': actualTripData['driverId'],
          'seats': selectedSeats,
          'totalPrice': totalPrice,
          'paymentMethod': paymentMethod,
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
          // Include trip info for easier access in 'My Bookings'
          'tripFrom': actualTripData['from'],
          'tripTo': actualTripData['to'],
          'tripDate': actualTripData['date'],
          'passengerName': passengerName.isNotEmpty ? passengerName : 'Unknown Passenger',
        });
        
        print('Booking created successfully:');
        print('- Booking ID: ${bookingRef.id}');
        print('- Trip ID: $tripId');
        print('- User ID: ${user.uid}');
        print('- Driver ID: ${actualTripData['driverId']}');
        print('- Seats: $selectedSeats');
        print('- Total Price: $totalPrice');
        print('- Payment Method: $paymentMethod');
        print('- Trip: ${actualTripData['from']} to ${actualTripData['to']}');
        print('- Passenger Name: $passengerName');
      });

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => BookingConfirmationPage(
            tripData: tripData,
            bookingId: bookingRef.id,
            selectedSeats: selectedSeats,
            totalPrice: totalPrice,
          ),
        ),
        (Route<dynamic> route) => route.isFirst,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book trip: $e')),
      );
    }
  }
} 