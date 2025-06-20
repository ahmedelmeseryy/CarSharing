import 'package:carsharing/pages/user/payment_page.dart';
import 'package:carsharing/pages/user/driver_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripDetailsPage extends StatefulWidget {
  final String tripId;

  const TripDetailsPage({super.key, required this.tripId});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  int _selectedSeats = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.tripId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Trip not found."));
          }

          final tripData = snapshot.data!.data() as Map<String, dynamic>;
          final availableSeats = tripData['seats'] as int;
          final driverId = tripData['driverId'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTripInfoCard(tripData),
                const SizedBox(height: 16),
                if (driverId != null)
                  _buildDriverInfoCard(driverId)
                else
                  const Card(
                    child: ListTile(
                      title: Text('Driver info not available'),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildSeatSelector(availableSeats),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: availableSeats > 0 ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PaymentPage(
                            tripData: tripData,
                            tripId: widget.tripId,
                            selectedSeats: _selectedSeats,
                          ),
                        ),
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                    child: const Text('Proceed to Payment'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripInfoCard(Map<String, dynamic> tripData) {
    String formattedDate = 'N/A';
    if (tripData['date'] is Timestamp) {
      formattedDate =
          DateFormat.yMMMMEEEEd().format((tripData['date'] as Timestamp).toDate());
    }
    final time = tripData['time'] ?? 'N/A';
    final price = tripData['price']?.toStringAsFixed(2) ?? 'N/A';
    final from = tripData['from'] ?? 'N/A';
    final to = tripData['to'] ?? 'N/A';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$from -> $to', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Date', formattedDate),
            _buildInfoRow(Icons.access_time, 'Time', time),
            _buildInfoRow(Icons.euro_symbol, 'Price per Seat', '€$price'),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard(String driverId) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(driverId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
              child: ListTile(title: Text('Driver info not available')));
        }
        final driverData = snapshot.data!.data() as Map<String, dynamic>;
        final driverName = driverData['name'] as String? ?? 'N/A';
        final carModel = driverData['carModel'] as String? ?? 'N/A';

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverProfilePage(
                              driverId: driverId,
                              driverName: driverName,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.person, size: 30, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('About the Driver', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(driverName, style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  ],
                ),
                const Divider(height: 20),
                _buildInfoRow(Icons.person, 'Name', driverName),
                _buildInfoRow(Icons.directions_car, 'Car Model', carModel),
                const SizedBox(height: 10),
                _buildReviewsSection(driverId),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsSection(String driverId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(driverId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(5) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return const Text('Could not load reviews.');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildInfoRow(Icons.star, 'Rating', 'No reviews yet');
        }

        final reviews = snapshot.data!.docs;
        double totalRating = 0;
        for (var doc in reviews) {
          final data = doc.data() as Map<String, dynamic>;
          totalRating += (data['rating'] as num?) ?? 0;
        }
        final avgRating = totalRating / reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.star, 'Rating', '${avgRating.toStringAsFixed(1)} (${reviews.length} reviews)'),
            const SizedBox(height: 16),
            Text('Recent Feedback:', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...reviews.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
              final comment = data['comment'] as String? ?? 'No comment';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text('"$comment"'),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildSeatSelector(int availableSeats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Select Seats', style: Theme.of(context).textTheme.titleLarge),
            if (availableSeats > 0)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _selectedSeats > 1
                        ? () => setState(() => _selectedSeats--)
                        : null,
                  ),
                  Text('$_selectedSeats', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _selectedSeats < availableSeats
                        ? () => setState(() => _selectedSeats++)
                        : null,
                  ),
                ],
              )
            else
              const Text('No seats available', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
} 