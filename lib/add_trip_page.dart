import 'package:carsharing/widgets/address_autocomplete_field.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/points.dart';
import 'package:carsharing/core/providers/mutation_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AddTripPage extends ConsumerStatefulWidget {
  const AddTripPage({super.key});

  @override
  ConsumerState<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends ConsumerState<AddTripPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _fromAddressController = TextEditingController();
  final _toAddressController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _seatsController = TextEditingController(text: '1');
  double? _fromLatitude;
  double? _fromLongitude;
  double? _toLatitude;
  double? _toLongitude;
  
  DateTime? _date;
  TimeOfDay? _time;
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to state changes for success/error feedback
    ref.listenManual(offerTripProvider, (previous, next) {
      if (!mounted) return;
      
      next.when(
        data: (response) {
          if (response != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            ref.read(offerTripProvider.notifier).reset();
            Navigator.of(context).pop();
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating trip: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        loading: () {},
      );
    });
  }

  @override
  void dispose() {
    _fromAddressController.dispose();
    _toAddressController.dispose();
    _vehicleNumberController.dispose();
    _seatsController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offerState = ref.watch(offerTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a New Trip'),
        actions: [
          const SizedBox.shrink(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Origin Address
              AddressAutocompleteField(
                controller: _fromAddressController,
                label: 'Starting Point (Exact Address)',
                hint: 'e.g., Hauptbahnhof, Berlin, Germany',
                prefixIcon: Icons.location_on,
                prefixIconColor: Colors.green,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter starting address' : null,
                onAddressSelected: (address, latitude, longitude) {
                  setState(() {
                    _fromLatitude = latitude;
                    _fromLongitude = longitude;
                  });
                },
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 16),
              // Destination Address
              AddressAutocompleteField(
                controller: _toAddressController,
                label: 'Destination (Exact Address)',
                hint: 'e.g., Marienplatz, Munich, Germany',
                prefixIcon: Icons.location_on,
                prefixIconColor: Colors.red,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter destination address' : null,
                onAddressSelected: (address, latitude, longitude) {
                  setState(() {
                    _toLatitude = latitude;
                    _toLongitude = longitude;
                  });
                },
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., ABC-1234',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter vehicle number' : null,
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) =>
                    value!.isEmpty ? 'Please select a date' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: _selectTime,
                validator: (value) =>
                    value!.isEmpty ? 'Please select a time' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seatsController,
                decoration: const InputDecoration(
                  labelText: 'Available Seats',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      int.tryParse(value) == null ||
                      int.parse(value) <= 0) {
                    return 'Please enter a valid number of seats';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: offerState.isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: offerState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
        _dateController.text = DateFormat.yMd().format(_date!);
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
        _timeController.text = _time!.format(context);
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final seats = int.tryParse(_seatsController.text);
    if (seats == null || seats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of seats'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fromLatitude == null || _fromLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a starting address from suggestions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_toLatitude == null || _toLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination from suggestions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add a trip'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final startDateTimeLocal = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    final request = OfferRideRequest(
      driverId: user.uid,
      vehicleNumber: _vehicleNumberController.text.trim(),
      sourceAddress: Points(
        latitude: _fromLatitude!,
        longitude: _fromLongitude!,
        placeAddress: _fromAddressController.text,
      ),
      destinationAddress: Points(
        latitude: _toLatitude!,
        longitude: _toLongitude!,
        placeAddress: _toAddressController.text,
      ),
      tripStartDateTime: startDateTimeLocal.toUtc(),
      totalSeats: seats,
    );

    // Call offerTrip - the listener will handle success/error
    final notifier = ref.read(offerTripProvider.notifier);
    await notifier.offerTrip(request);
  }
} 