import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carsharing/features/booking/data/models/booking_response.dart';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/features/trip/data/services/trip_api_service.dart';

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
  List<dynamic> _passengers = [];
  bool _loadingPassengers = true;

  @override
  void initState() {
    super.initState();
    _fetchPassengers();
  }

  Future<void> _fetchPassengers() async {
    final tripId = widget.trip.tripId;
    if (tripId == null || tripId.isEmpty) {
      setState(() => _loadingPassengers = false);
      return;
    }
    try {
      final service = TripApiService(DioClient());
      final data = await service.getTripById(tripId);
      if (data != null) {
        final raw = data['passengers'];
        setState(() {
          _passengers = raw is List ? raw : [];
          _loadingPassengers = false;
        });
      } else {
        setState(() => _loadingPassengers = false);
      }
    } catch (_) {
      setState(() => _loadingPassengers = false);
    }
  }

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
    final parsedDate = trip.tripStartDateTime != null
        ? DateTime.tryParse(trip.tripStartDateTime!)
        : null;
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

    final price = trip.pricePerSeat != null
        ? '€${trip.pricePerSeat!.toStringAsFixed(2)} / seat'
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
              softWrap: true,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Date', formattedDate),
            _buildInfoRow(Icons.access_time, 'Time', formattedTime),
            _buildInfoRow(Icons.euro, 'Price', price),
            _buildInfoRow(Icons.event_seat, 'Total Seats', '${trip.totalSeats}'),
            _buildInfoRow(Icons.people, 'Booked Seats', '${trip.bookedSeats}'),
            _buildInfoRow(Icons.event_available, 'Available Seats', '${trip.availableSeats}'),
            _buildInfoRow(Icons.route, 'Distance', distance),
            _buildInfoRow(Icons.timer, 'Duration', duration),
            _buildInfoRow(Icons.directions_car, 'Vehicle', trip.vehicleNumber ?? 'N/A'),
            _buildInfoRow(Icons.info, 'Status', trip.tripStatus ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Passengers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.trip.bookedSeats} booked',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() => _loadingPassengers = true);
                    _fetchPassengers();
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingPassengers)
              const Center(child: CircularProgressIndicator())
            else if (_passengers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.trip.bookedSeats > 0
                        ? 'Passengers have booked but details are not available yet.'
                        : 'No passengers have booked this trip yet.',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _passengers.length,
                itemBuilder: (context, index) {
                  final passenger = _passengers[index];
                  final data = _normalizePassenger(passenger);

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
                      title: Text(data.name),
                      subtitle: _buildPassengerSubtitle(data),
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
      final seats = (passenger['bookedSeats'] ?? passenger['seats'] ?? passenger['requestedSeats'])?.toString();
      final id = (passenger['passengerId'] ?? passenger['userId'] ?? passenger['id'])?.toString();

      return _PassengerDisplayData(
        name: name?.isNotEmpty == true ? name! : (id ?? 'Passenger'),
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
    if (data.email != null && data.email!.isNotEmpty) details.add(data.email!);
    if (data.phone != null && data.phone!.isNotEmpty) details.add(data.phone!);
    if (data.seats != null && data.seats!.isNotEmpty) details.add('Seats: ${data.seats}');
    if (details.isEmpty && data.id != null && data.id!.isNotEmpty) details.add('ID: ${data.id}');
    if (details.isEmpty) return null;
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
