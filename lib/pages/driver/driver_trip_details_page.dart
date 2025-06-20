import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverTripDetailsPage extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> tripData;

  const DriverTripDetailsPage({
    super.key,
    required this.tripId,
    required this.tripData,
  });

  @override
  State<DriverTripDetailsPage> createState() => _DriverTripDetailsPageState();
}

class _DriverTripDetailsPageState extends State<DriverTripDetailsPage> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _seatsController;
  late TextEditingController _priceController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final tripData = widget.tripData;
    _seatsController = TextEditingController(text: tripData['seats'].toString());
    _priceController = TextEditingController(text: tripData['price'].toString());
    
    if (tripData['date'] is Timestamp) {
      _selectedDate = (tripData['date'] as Timestamp).toDate();
    } else {
      _selectedDate = DateTime.now();
    }
    
    // Default time if not available
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _seatsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _initializeControllers(); // Reset to original values
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
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
    final tripData = widget.tripData;
    final from = tripData['from'] ?? 'N/A';
    final to = tripData['to'] ?? 'N/A';
    
    String formattedDate = 'N/A';
    if (tripData['date'] is Timestamp) {
      formattedDate = DateFormat.yMMMMEEEEd().format((tripData['date'] as Timestamp).toDate());
    }

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
                Expanded(
                  child: Text(
                    '$from → $to',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (_isEditing)
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('Save'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              _buildEditForm(),
            ] else ...[
              _buildInfoRow(Icons.calendar_today, 'Date', formattedDate),
              _buildInfoRow(Icons.euro_symbol, 'Price per Seat', '€${tripData['price']}'),
              _buildInfoRow(Icons.event_seat, 'Available Seats', '${tripData['seats']}'),
              _buildInfoRow(Icons.person, 'Driver', tripData['driverName'] ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _seatsController,
            decoration: const InputDecoration(
              labelText: 'Available Seats',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'Please enter a valid number of seats';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price per Seat (€)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                return 'Please enter a valid price';
              }
              return null;
            },
          ),
        ],
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
            Text(
              'Bookings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('tripId', isEqualTo: widget.tripId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No bookings yet for this trip.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final bookings = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final bookingData = booking.data() as Map<String, dynamic>;
                    
                    String formattedDate = 'N/A';
                    if (bookingData['createdAt'] is Timestamp) {
                      formattedDate = DateFormat.yMd().format((bookingData['createdAt'] as Timestamp).toDate());
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${bookingData['passengerName'] ?? 'Unknown Passenger'}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Seats: ${bookingData['seats']}'),
                            Text('Total: €${bookingData['totalPrice']}'),
                            Text('Booked: $formattedDate'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildBookingStatusChip(bookingData['status'] ?? 'pending'),
                            const SizedBox(width: 8),
                            if (bookingData['status'] != 'cancelled')
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _showCancelBookingDialog(booking.id, bookingData),
                                tooltip: 'Cancel Booking',
                              ),
                          ],
                        ),
                        onTap: () => _showBookingDetails(bookingData),
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

  Widget _buildBookingStatusChip(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        text = 'Confirmed';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
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

  void _showBookingDetails(Map<String, dynamic> bookingData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passenger: ${bookingData['passengerName'] ?? 'Unknown'}'),
            Text('Trip: ${bookingData['tripFrom']} to ${bookingData['tripTo']}'),
            Text('Seats: ${bookingData['seats']}'),
            Text('Total Price: €${bookingData['totalPrice']}'),
            Text('Payment Method: ${bookingData['paymentMethod'] ?? 'N/A'}'),
            Text('Status: ${bookingData['status'] ?? 'pending'}'),
            if (bookingData['createdAt'] is Timestamp)
              Text('Booked: ${DateFormat.yMd().add_jm().format((bookingData['createdAt'] as Timestamp).toDate())}'),
            if (bookingData['tripDate'] is Timestamp)
              Text('Trip Date: ${DateFormat.yMd().add_jm().format((bookingData['tripDate'] as Timestamp).toDate())}'),
            if (bookingData['status'] == 'cancelled' && bookingData['cancelledAt'] is Timestamp) ...[
              const SizedBox(height: 8),
              Text('Cancelled: ${DateFormat.yMd().add_jm().format((bookingData['cancelledAt'] as Timestamp).toDate())}'),
              Text('Cancelled by: ${bookingData['cancelledBy'] ?? 'Unknown'}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final seats = int.parse(_seatsController.text);
      final price = double.parse(_priceController.text);

      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'seats': seats,
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCancelBookingDialog(String bookingId, Map<String, dynamic> bookingData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel the booking for ${bookingData['passengerName'] ?? 'this passenger'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleCancelBooking(bookingId, bookingData);
    }
  }

  Future<void> _handleCancelBooking(String bookingId, Map<String, dynamic> bookingData) async {
    try {
      // Update booking status to cancelled
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'driver',
      });

      // Refund seats to the trip
      final tripRef = FirebaseFirestore.instance.collection('trips').doc(widget.tripId);
      final tripDoc = await tripRef.get();
      if (tripDoc.exists) {
        final currentSeats = tripDoc.data()!['seats'] as int;
        final refundedSeats = bookingData['seats'] as int;
        await tripRef.update({
          'seats': currentSeats + refundedSeats,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 