import 'package:flutter/material.dart';

class ConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> ride;
  final int selectedSeat;

  const ConfirmationPage(
      {super.key, required this.ride, required this.selectedSeat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildConfirmationHeader(),
              const SizedBox(height: 32),
              _buildRideDetailsCard(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/dashboard', (Route<dynamic> route) => false);
                },
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationHeader() {
    return const Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white, size: 60),
        ),
        SizedBox(height: 16),
        Text(
          'Booking Successful!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'You are all set. Please find your ride details below.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRideDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                Icons.location_on, 'From', ride['start']),
            const Divider(height: 24),
            _buildDetailRow(Icons.flag, 'To', ride['end']),
            const Divider(height: 24),
            _buildDetailRow(
                Icons.calendar_today, 'Date', ride['date']),
            const Divider(height: 24),
            _buildDetailRow(Icons.access_time, 'Time', ride['time']),
             const Divider(height: 24),
            _buildDetailRow(
                Icons.airline_seat_recline_normal, 'Seat', '$selectedSeat'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 16),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(value),
      ],
    );
  }
} 