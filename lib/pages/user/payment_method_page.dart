import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carsharing/features/trip/data/models/trip.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';
import 'package:carsharing/core/providers/mutation_providers.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/pages/user/booking_confirmation_page.dart';

enum PaymentMethod { cash, card }

class PaymentMethodPage extends ConsumerStatefulWidget {
  final Trip trip;
  final int selectedSeats;

  const PaymentMethodPage({
    super.key,
    required this.trip,
    required this.selectedSeats,
  });

  @override
  ConsumerState<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends ConsumerState<PaymentMethodPage> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final totalPrice =
        (widget.trip.estimatedFare * widget.selectedSeats).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Seats', '${widget.selectedSeats}'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Price per seat',
                        '€${widget.trip.estimatedFare.toStringAsFixed(2)}'),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '€$totalPrice',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Cash Payment Option
            Card(
              elevation: _selectedMethod == PaymentMethod.cash ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedMethod == PaymentMethod.cash
                      ? Colors.blue
                      : Colors.grey.shade300,
                  width: _selectedMethod == PaymentMethod.cash ? 2 : 1,
                ),
              ),
              child: RadioListTile<PaymentMethod>(
                value: PaymentMethod.cash,
                groupValue: _selectedMethod,
                onChanged: _isProcessing
                    ? null
                    : (value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                title: const Row(
                  children: [
                    Icon(Icons.money, color: Colors.green),
                    SizedBox(width: 12),
                    Text(
                      'Cash',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(left: 44.0, top: 4),
                  child: Text('Pay the driver in cash'),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Card Payment Option
            Card(
              elevation: _selectedMethod == PaymentMethod.card ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedMethod == PaymentMethod.card
                      ? Colors.blue
                      : Colors.grey.shade300,
                  width: _selectedMethod == PaymentMethod.card ? 2 : 1,
                ),
              ),
              child: RadioListTile<PaymentMethod>(
                value: PaymentMethod.card,
                groupValue: _selectedMethod,
                onChanged: _isProcessing
                    ? null
                    : (value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                title: const Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue),
                    SizedBox(width: 12),
                    Text(
                      'Credit/Debit Card',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(left: 44.0, top: 4),
                  child: Text('Pay securely with your card'),
                ),
              ),
            ),

            const Spacer(),

            if (_isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing your booking...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Confirm Booking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmBooking() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final tokenStorage = ref.read(secureStorageProvider);
      final userId = await tokenStorage.getUserId();

      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to book this trip.')),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final request = JoinTripRequest(
        tripId: widget.trip.tripId!,
        passengerId: userId,
        driverId: widget.trip.driverId,
        pickupPoint: widget.trip.sourceAddress,
        destinationPoint: widget.trip.destinationAddress,
        rideStartTime: widget.trip.tripStartDateTime.toUtc().toIso8601String(),
        requestedSeats: widget.selectedSeats,
      );

      final notifier = ref.read(joinTripProvider.notifier);
      
      // Call the booking
      await notifier.joinTrip(request);
      print('✅ PAYMENT: Booking notifier call completed');
      
      // Wait a brief moment for state to update
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Now read the final state
      final state = ref.read(joinTripProvider);
      print('✅ PAYMENT: Final state after delay: $state');
      print('✅ PAYMENT: State hasValue: ${state.hasValue}, State.hasError: ${state.hasError}');
      
      // Handle the state
      if (state.hasError) {
        print('❌ PAYMENT: State has error: ${state.error}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking error: ${state.error}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }
      
      if (!state.hasValue || state.value == null) {
        print('⚠️ PAYMENT: State has no value');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking in progress...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }
      
      // Success case
      final booking = state.value!;
      print('✅ PAYMENT: Booking successful, rideId: ${booking.rideId}');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip booked successfully! ✅'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Add to local cache
      ref.read(localBookingsCacheProvider(userId).notifier).addBooking(booking);
      
      // Invalidate bookings cache
      ref.invalidate(getUpcomingBookingsForPassengerProvider(userId));
      
      // Navigate to confirmation page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmationPage(
              trip: widget.trip,
              selectedSeats: widget.selectedSeats,
              paymentMethod: _selectedMethod == PaymentMethod.cash
                  ? 'Cash'
                  : 'Credit/Debit Card',
              booking: booking,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString();
      if (errorMessage.contains('ALREADY_BOOKED')) {
        errorMessage = 'You have already booked this trip';
      } else if (errorMessage.contains('409')) {
        errorMessage = 'This trip is no longer available';
      } else {
        errorMessage = 'Error: ${errorMessage.split('\n').first}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
