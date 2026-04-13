import 'package:carsharing/shared/widgets/address_autocomplete_field.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/points.dart';
import 'package:carsharing/core/providers/mutation_providers.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/core/storage/secure_storage.dart';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/features/user/data/services/user_api_service.dart';
import 'package:carsharing/features/driver/presentation/register_vehicle_page.dart';
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
  final _seatsController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  double? _fromLatitude;
  double? _fromLongitude;
  double? _toLatitude;
  double? _toLongitude;

  DateTime? _date;
  TimeOfDay? _time;
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic>? _selectedVehicle;
  bool _vehiclesLoading = true;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _loadVehicles();

    ref.listenManual(offerTripProvider, (previous, next) {
      if (!mounted) return;
      next.when(
        data: (response) {
          if (response != null) {
            if (response.tripId == null || response.tripId!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(response.errorMessage ?? 'Failed to create trip'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            ref.read(offerTripProvider.notifier).reset();
            if (_driverId != null) {
              ref.invalidate(getUpcomingTripsForDriverProvider(_driverId!));
            }
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

  Future<void> _loadVehicles() async {
    setState(() => _vehiclesLoading = true);
    try {
      final userId = await TokenStorage().getUserId() ?? '';
      final vehicles = await UserApiService(DioClient()).getVehiclesByUserId(userId);
      setState(() {
        _vehicles = vehicles;
        _selectedVehicle = vehicles.isNotEmpty ? vehicles.first : null;
        _vehiclesLoading = false;
      });
    } catch (_) {
      setState(() => _vehiclesLoading = false);
    }
  }

  @override
  void dispose() {
    _fromAddressController.dispose();
    _toAddressController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offerState = ref.watch(offerTripProvider);

    if (_vehiclesLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add a New Trip')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_vehicles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add a New Trip')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_outlined, size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 24),
                const Text(
                  'No Vehicle Registered',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'You need to register a vehicle before you can create a trip.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Register a Vehicle'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterVehiclePage()),
                      );
                      _loadVehicles();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add a New Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle selector
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedVehicle,
                decoration: const InputDecoration(
                  labelText: 'Select Vehicle',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                items: _vehicles.map((v) {
                  final name = v['vehicleName'] ?? v['text'] ?? 'Unknown';
                  final plate = v['vehicleNumber'] ?? v['value'] ?? '';
                  final label = plate.isNotEmpty ? '$name — $plate' : name;
                  return DropdownMenuItem(value: v, child: Text(label, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) => setState(() => _selectedVehicle = v),
                validator: (_) => _selectedVehicle == null ? 'Select a vehicle' : null,
              ),
              const SizedBox(height: 16),

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
                validator: (value) => value!.isEmpty ? 'Please select a date' : null,
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
                validator: (value) => value!.isEmpty ? 'Please select a time' : null,
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
                  hintText: 'e.g., 10',
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price per seat';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null || price < 1 || price > 1000) {
                    return 'Price must be between €1 and €1000';
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
    if (seats == null || seats <= 0) return;

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
        const SnackBar(content: Text('Please select date and time'), backgroundColor: Colors.red),
      );
      return;
    }

    final userId = await TokenStorage().getUserId();
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add a trip')),
      );
      return;
    }
    _driverId = userId;

    final startDateTimeLocal = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    final vehicleNumber = (_selectedVehicle?['vehicleNumber'] ?? _selectedVehicle?['value'])?.toString();

    final request = OfferRideRequest(
      driverId: userId,
      vehicleNumber: vehicleNumber,
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
      pricePerSeat: double.parse(_priceController.text.trim()),
    );

    final notifier = ref.read(offerTripProvider.notifier);
    await notifier.offerTrip(request);
  }
}
