import 'package:carsharing/user_dashboard_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> tripData;
  final String bookingId;
  final int selectedSeats;
  final double totalPrice;

  const BookingConfirmationPage({
    super.key,
    required this.tripData,
    required this.bookingId,
    required this.selectedSeats,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = 'N/A';
    if (tripData['date'] is Timestamp) {
      formattedDate =
          DateFormat.yMMMMEEEEd().format((tripData['date'] as Timestamp).toDate());
    }
    final time = tripData['time'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 100),
            const SizedBox(height: 20),
            Text(
              'Thank You!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your trip has been booked successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildConfirmationCard(formattedDate, time),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const UserDashboardPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationCard(String formattedDate, String time) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Booking Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildDetailRow('From', tripData['from']),
            _buildDetailRow('To', tripData['to']),
            _buildDetailRow('Date', formattedDate),
            _buildDetailRow('Time', time),
            _buildDetailRow('Seats', '$selectedSeats'),
            _buildDetailRow('Total Price', '€${totalPrice.toStringAsFixed(2)}'),
            _buildDetailRow('Booking ID', bookingId),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 