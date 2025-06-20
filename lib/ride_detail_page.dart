import 'package:flutter/material.dart';
import 'driver_profile_page.dart';
import 'seat_selection_page.dart';

class RideDetailPage extends StatelessWidget {
  final Map<String, dynamic> ride;
  const RideDetailPage({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${ride['start']} to ${ride['end']}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildRideInfoCard(),
            const SizedBox(height: 24),
            _buildDriverCard(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBookingBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${ride['date']} at ${ride['time']}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'From: ${ride['start']}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.flag, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'To: ${ride['end']}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRideInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem(Icons.event_seat, '${ride['seats_available']} Seats', 'Available'),
            _buildInfoItem(Icons.attach_money, '€${ride['price']}', 'Per Seat'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 30),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildDriverCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, size: 30, color: Colors.blue),
        ),
        title: Text(ride['driver'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('View Profile'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DriverProfilePage(
              driverName: ride['driver'],
              carModel: ride['car_model'],
            )),
          );
        },
      ),
    );
  }

  Widget _buildBookingBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeatSelectionPage(
                  ride: ride,
                ),
              ),
            );
          },
          child: const Text('Book Now'),
        ),
      ),
    );
  }
} 