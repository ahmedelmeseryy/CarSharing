import 'package:flutter/material.dart';

class DriverProfilePage extends StatelessWidget {
  final String driverName;
  final String? carModel;

  const DriverProfilePage({super.key, required this.driverName, this.carModel});

  @override
  Widget build(BuildContext context) {
    // In a real app, you'd fetch this data from a backend
    // based on the driver's name or ID.
    final driverData = {
      'name': driverName,
      'rating': 4.8,
      'trips': 123,
      'member_since': '2021',
      'bio':
          'Hi, I am $driverName! I am a friendly and safe driver with a clean and comfortable car. I enjoy meeting new people and ensuring a pleasant journey for my passengers. Looking forward to driving with you!',
      'car_model': carModel ?? 'Toyota Camry 2022',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(driverName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(driverData),
          const SizedBox(height: 24),
          _buildStatsCard(driverData),
          const SizedBox(height: 24),
          _buildInfoCard('About Me', driverData['bio'] as String, Icons.person_outline),
          const SizedBox(height: 16),
           _buildInfoCard('Vehicle', driverData['car_model'] as String, Icons.directions_car),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> driverData) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.person, size: 60, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            driverData['name'] as String,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Member since ${driverData['member_since']}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> driverData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.star_border, (driverData['rating'] as double).toString(), 'Rating'),
            _buildStatItem(Icons.card_travel, (driverData['trips'] as int).toString(), 'Trips'),
          ],
        ),
      ),
    );
  }

   Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 30),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(content, style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5)),
          ],
        ),
      ),
    );
  }
} 