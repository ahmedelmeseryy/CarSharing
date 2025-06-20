import 'package:flutter/material.dart';
import 'confirmation_page.dart';

class SeatSelectionPage extends StatefulWidget {
  final Map<String, dynamic> ride;

  const SeatSelectionPage({super.key, required this.ride});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final Set<int> _selectedSeats = {};

  @override
  Widget build(BuildContext context) {
    // Example layout: 2 seats in front (1 is driver), 3 in middle, 3 in back
    // We assume seat 1 is the driver.
    final int totalSeats = widget.ride['seats_available'] ?? 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Seat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Front"),
                  const SizedBox(height: 8),
                  // Row 1 (Driver + 1 passenger)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSeat(1, isDriver: true),
                      _buildSeat(2, isEnabled: totalSeats >= 1),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Middle"),
                   const SizedBox(height: 8),
                  // Row 2 (3 passengers)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSeat(3, isEnabled: totalSeats >= 2),
                      _buildSeat(4, isEnabled: totalSeats >= 3),
                      _buildSeat(5, isEnabled: totalSeats >= 4),
                    ],
                  ),
                   const SizedBox(height: 24),
                   const Text("Back"),
                   const SizedBox(height: 8),
                  // Row 3 (3 passengers)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSeat(6, isEnabled: totalSeats >= 5),
                      _buildSeat(7, isEnabled: totalSeats >= 6),
                      _buildSeat(8, isEnabled: totalSeats >= 7),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildConfirmationBar(),
        ],
      ),
    );
  }

  Widget _buildSeat(int seatNumber, {bool isDriver = false, bool isEnabled = true}) {
    final isSelected = _selectedSeats.contains(seatNumber);
    final isBooked = !isEnabled; // A simple way to show booked seats

    Color iconColor = Colors.grey.shade400;
    if (isDriver) {
      iconColor = Colors.blueGrey.shade800;
    } else if (isBooked) {
      iconColor = Colors.red.shade300;
    } else if (isSelected) {
      iconColor = Colors.blue;
    }

    return GestureDetector(
      onTap: isDriver || isBooked ? null : () {
        setState(() {
          if (isSelected) {
            _selectedSeats.remove(seatNumber);
          } else {
            // Allow only one selection for now
            _selectedSeats.clear();
            _selectedSeats.add(seatNumber);
          }
        });
      },
      child: Column(
        children: [
          Icon(
            isDriver ? Icons.person_pin : Icons.event_seat,
            size: 60,
            color: iconColor,
          ),
          Text(isDriver ? 'Driver' : 'Seat $seatNumber'),
        ],
      ),
    );
  }
  
  Widget _buildConfirmationBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _selectedSeats.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfirmationPage(
                        ride: widget.ride,
                        selectedSeat: _selectedSeats.first,
                      ),
                    ),
                  );
                },
          child: Text(_selectedSeats.isEmpty
              ? 'Please select a seat'
              : 'Confirm Seat ${_selectedSeats.first}'),
        ),
      ),
    );
  }
} 