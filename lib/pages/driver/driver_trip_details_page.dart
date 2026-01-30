import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carsharing/features/trip/data/models/trip.dart';

class DriverTripDetailsPage extends StatefulWidget {
  final Trip trip;

  const DriverTripDetailsPage({
    super.key,
    required this.trip,
  });

  @override
  State<DriverTripDetailsPage> createState() => _DriverTripDetailsPageState();
}

class _DriverTripDetailsPageState extends State<DriverTripDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripInfoCard(),
            const SizedBox(height: 16),
            _buildBookingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfoCard() {
    final trip = widget.trip;
    final from = trip.sourceAddress?.placeAddress ?? 'N/A';
    final to = trip.destinationAddress?.placeAddress ?? 'N/A';
    
    String formattedDate = 'N/A';
    String formattedTime = 'N/A';
    if (trip.tripStartDateTime != null) {
      formattedDate = DateFormat.yMMMMEEEEd().format(trip.tripStartDateTime!);
      formattedTime = DateFormat.jm().format(trip.tripStartDateTime!);
    }

    final distance = trip.routeDistance != null 
        ? '${(trip.routeDistance! / 1000).toStringAsFixed(1)} km' 
        : 'N/A';
    
    final duration = trip.routeDuration != null
        ? '${(trip.routeDuration! / 60).toStringAsFixed(0)} min'
        : 'N/A';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$from → $to',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Date', formattedDate),
            _buildInfoRow(Icons.access_time, 'Time', formattedTime),
            _buildInfoRow(Icons.euro_symbol, 'Price per km', '€${trip.pricePerKm?.toStringAsFixed(2) ?? 'N/A'}'),
            _buildInfoRow(Icons.event_seat, 'Offered Seats', '${trip.totalSeats}'),
            _buildInfoRow(Icons.people, 'Booked Seats', '${trip.bookedSeats}'),
            _buildInfoRow(Icons.event_available, 'Available Seats', '${trip.availableSeats}'),
            _buildInfoRow(Icons.route, 'Distance', distance),
            _buildInfoRow(Icons.timer, 'Duration', duration),
            _buildInfoRow(Icons.directions_car, 'Vehicle', trip.vehicleNumber),
            _buildInfoRow(Icons.info, 'Status', trip.tripStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsSection() {
    final trip = widget.trip;
    final joinedRiders = trip.joinedRidersId ?? [];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Passengers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${joinedRiders.length} ${joinedRiders.length == 1 ? 'booking' : 'bookings'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (joinedRiders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No passengers have booked this trip yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: joinedRiders.length,
                itemBuilder: (context, index) {
                  final riderId = joinedRiders[index].toString();
                  
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(riderId)
                        .get(),
                    builder: (context, snapshot) {
                      String passengerName = 'Passenger ${index + 1}';
                      String? email;
                      
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>?;
                        passengerName = userData?['name'] as String? ?? 'Unknown Passenger';
                        email = userData?['email'] as String?;
                      }
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(passengerName),
                          subtitle: email != null ? Text(email) : null,
                          trailing: const Icon(Icons.check_circle, color: Colors.green),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
} 