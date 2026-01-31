import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';

class DriverTripDetailsPage extends StatefulWidget {
  final DriverTripResponse trip;

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
    final from = trip.sourceAddress.placeAddress ?? 'N/A';
    final to = trip.destinationAddress.placeAddress ?? 'N/A';
    
    String formattedDate = 'N/A';
    String formattedTime = 'N/A';
    final parsedDate = DateTime.tryParse(trip.tripStartDateTime);
    if (parsedDate != null) {
      formattedDate = DateFormat.yMMMMEEEEd().format(parsedDate.toLocal());
      formattedTime = DateFormat.jm().format(parsedDate.toLocal());
    }

    final distance = trip.routeDistanceInKm != null 
      ? '${trip.routeDistanceInKm!.toStringAsFixed(1)} km' 
      : 'N/A';
    
    final duration = trip.routeDurationInMinutes != null
      ? '${trip.routeDurationInMinutes!.toStringAsFixed(0)} min'
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
    final passengers = trip.passengers ?? [];
    
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
                    '${passengers.length} ${passengers.length == 1 ? 'booking' : 'bookings'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (passengers.isEmpty)
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
                itemCount: passengers.length,
                itemBuilder: (context, index) {
                  final passenger = passengers[index];
                  final passengerData = _normalizePassenger(passenger);

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
                      title: Text(passengerData.name),
                      subtitle: _buildPassengerSubtitle(passengerData),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  _PassengerDisplayData _normalizePassenger(dynamic passenger) {
    if (passenger is Map<String, dynamic>) {
      final name = (passenger['name'] ??
              passenger['fullName'] ??
              passenger['passengerName'] ??
              passenger['userName'])
          ?.toString();
      final email = passenger['email']?.toString();
      final phone = (passenger['phone'] ?? passenger['phoneNumber'])?.toString();
      final seats = (passenger['bookedSeats'] ?? passenger['seats'])?.toString();
      final id = (passenger['passengerId'] ?? passenger['userId'] ?? passenger['id'])?.toString();

      return _PassengerDisplayData(
        name: name?.isNotEmpty == true ? name! : 'Passenger',
        email: email,
        phone: phone,
        seats: seats,
        id: id,
      );
    }

    return _PassengerDisplayData(
      name: passenger?.toString() ?? 'Passenger',
      id: passenger?.toString(),
    );
  }

  Widget? _buildPassengerSubtitle(_PassengerDisplayData data) {
    final details = <String>[];
    if (data.email != null && data.email!.isNotEmpty) {
      details.add(data.email!);
    }
    if (data.phone != null && data.phone!.isNotEmpty) {
      details.add(data.phone!);
    }
    if (data.seats != null && data.seats!.isNotEmpty) {
      details.add('Seats: ${data.seats}');
    }
    if (details.isEmpty && data.id != null && data.id!.isNotEmpty) {
      details.add('ID: ${data.id}');
    }

    if (details.isEmpty) {
      return null;
    }

    return Text(details.join(' • '));
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

class _PassengerDisplayData {
  final String name;
  final String? email;
  final String? phone;
  final String? seats;
  final String? id;

  const _PassengerDisplayData({
    required this.name,
    this.email,
    this.phone,
    this.seats,
    this.id,
  });
}