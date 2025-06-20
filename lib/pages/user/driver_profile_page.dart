import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverProfilePage extends StatefulWidget {
  final String driverId;
  final String driverName;

  const DriverProfilePage({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.driverId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Driver not found."));
          }

          final driverData = snapshot.data!.data() as Map<String, dynamic>;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(driverData),
                const SizedBox(height: 24),
                _buildDriverInfoCard(driverData),
                const SizedBox(height: 16),
                _buildRatingSection(),
                const SizedBox(height: 16),
                _buildReviewsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> driverData) {
    final name = driverData['name'] as String? ?? '';
    final surname = driverData['surname'] as String? ?? '';
    final fullName = '$name $surname'.trim();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'D',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fullName.isNotEmpty ? fullName : 'Unknown Driver',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Professional Driver',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard(Map<String, dynamic> driverData) {
    final phone = driverData['phone'] as String? ?? 'N/A';
    final carModel = driverData['car_model'] as String? ?? 'N/A';
    final carColor = driverData['car_color'] as String? ?? 'N/A';
    final carYear = driverData['car_year'] as String? ?? 'N/A';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone, 'Phone', phone),
            const Divider(height: 20),
            Text(
              'Vehicle Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.directions_car, 'Car Model', carModel),
            _buildInfoRow(Icons.palette, 'Car Color', carColor),
            _buildInfoRow(Icons.calendar_today, 'Car Year', carYear),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.driverId)
          .collection('reviews')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Could not load ratings.'),
            ),
          );
        }

        final reviews = snapshot.data?.docs ?? [];
        double averageRating = 0.0;
        
        if (reviews.isNotEmpty) {
          double totalRating = 0.0;
          for (var doc in reviews) {
            final data = doc.data() as Map<String, dynamic>;
            totalRating += (data['rating'] as num?)?.toDouble() ?? 0.0;
          }
          averageRating = totalRating / reviews.length;
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating & Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < averageRating.floor() 
                                  ? Icons.star 
                                  : index < averageRating 
                                      ? Icons.star_half 
                                      : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                        Text(
                          '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.driverId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Could not load reviews.'),
            ),
          );
        }

        final reviews = snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return Card(
            elevation: 4,
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'No reviews yet. Be the first to review this driver!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...reviews.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
                  final comment = data['comment'] as String? ?? '';
                  final reviewerName = data['reviewerName'] as String? ?? 'Anonymous';
                  
                  String formattedDate = 'N/A';
                  if (data['createdAt'] is Timestamp) {
                    formattedDate = DateFormat.yMd().format((data['createdAt'] as Timestamp).toDate());
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey.shade200,
                              child: Text(
                                reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'A',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reviewerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(comment),
                        ],
                        if (doc != reviews.last) const Divider(height: 16),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
} 