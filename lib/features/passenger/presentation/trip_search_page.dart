import 'package:carsharing/shared/widgets/address_autocomplete_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/shared/widgets/map_location_picker.dart';
import 'package:carsharing/shared/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carsharing/features/passenger/presentation/trip_search_results_page.dart';

class TripSearchPage extends ConsumerStatefulWidget {
  const TripSearchPage({super.key});

  @override
  ConsumerState<TripSearchPage> createState() => _TripSearchPageState();
}

class _TripSearchPageState extends ConsumerState<TripSearchPage> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  double? _fromLatitude;
  double? _fromLongitude;
  double? _toLatitude;
  double? _toLongitude;
  
  DateTime? _selectedDate;
  final _dateController = TextEditingController();
  TimeOfDay? _selectedTime;
  final _timeController = TextEditingController();
  
  // Advanced search filters
  double _minPrice = 0;
  double _maxPrice = 500;
  double _selectedMinPrice = 0;
  double _selectedMaxPrice = 500;
  int _selectedSeats = 1;
  double _sourceRadiusKm = 10;
  double _destRadiusKm = 10;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat.yMd().format(_selectedDate!);
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        final local = DateTime(0, 1, 1, picked.hour, picked.minute);
        _timeController.text = DateFormat.Hm().format(local);
      });
    }
  }

  Future<void> _searchTrips() async {
    if (_formKey.currentState!.validate()) {
      if (_fromController.text.isEmpty || _toController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter both origin and destination'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        if (_fromLatitude == null || _fromLongitude == null || _toLatitude == null || _toLongitude == null) {
          if (!context.mounted) return;
          // Close loading dialog first
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select locations from the autocomplete or map to search.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final tokenStorage = ref.read(secureStorageProvider);
        final userId = await tokenStorage.getUserId();
        if (userId == null || userId.isEmpty) {
          if (!context.mounted) return;
          // Close loading dialog first
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not determine user id. Please re-login.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // If date/time not selected, use current time to match all upcoming trips
        // Otherwise use selected date/time
        String rideStartIso;
        if (_selectedDate == null || _selectedTime == null) {
          // Use current date/time to get all upcoming trips
          final now = DateTime.now();
          rideStartIso = now.toUtc().toIso8601String();
        } else {
          final combinedLocal = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
          rideStartIso = combinedLocal.toUtc().toIso8601String();
        }

        
        final repository = ref.read(tripRepositoryProvider);
        final trips = await repository.searchMatchingRoute(
          sourceLat: _fromLatitude!,
          sourceLon: _fromLongitude!,
          sourceRadiusKm: _sourceRadiusKm,
          destLat: _toLatitude!,
          destLon: _toLongitude!,
          destRadiusKm: _destRadiusKm,
          requestedSeats: _selectedSeats,
          rideStartTime: rideStartIso,
          effectiveUserId: userId,
        );
        

        // Filter by price range and seats
        final filtered = trips.where((trip) {
          final fare = trip.estimatedFare;
          if (fare < _selectedMinPrice || fare > _selectedMaxPrice) {
            return false;
          }
          if (trip.freeSeats < _selectedSeats) {
            return false;
          }
          return true;
        }).toList();
        

        if (!context.mounted) return;
        
        // Close loading dialog
        Navigator.of(context).pop();
        
        if (filtered.isEmpty) {
          // Provide helpful message based on results
          String message;
          if (trips.isEmpty) {
            message = 'No trips found within $_sourceRadiusKm km of your origin and $_destRadiusKm km of your destination. Try increasing the search radius in advanced filters.';
          } else {
            message = 'Found ${trips.length} trip(s) but none match your filters. Try adjusting price range or number of seats.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripSearchResultsPage(
              trips: filtered,
              searchFrom: _fromController.text,
              searchTo: _toController.text,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        // Close loading dialog if still open
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Dialog may already be closed
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching trips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _useCurrentLocationForFrom() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      setState(() {
        _fromLatitude = pos.latitude;
        _fromLongitude = pos.longitude;
        _fromController.text = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
    }
  }

  Future<void> _openMapPickerForFrom() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLat: _fromLatitude,
          initialLon: _fromLongitude,
          onLocationSelected: (lat, lon, address) {
            setState(() {
              _fromLatitude = lat;
              _fromLongitude = lon;
              _fromController.text = address;
            });
          },
        ),
      ),
    );
  }

  Future<void> _useCurrentLocationForTo() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      setState(() {
        _toLatitude = pos.latitude;
        _toLongitude = pos.longitude;
        _toController.text = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
    }
  }

  Future<void> _openMapPickerForTo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLat: _toLatitude,
          initialLon: _toLongitude,
          onLocationSelected: (lat, lon, address) {
            setState(() {
              _toLatitude = lat;
              _toLongitude = lon;
              _toController.text = address;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search for Rides'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Where do you want to go?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Origin
              AddressAutocompleteField(
                controller: _fromController,
                label: 'From',
                hint: 'Enter your starting point',
                prefixIcon: Icons.location_on,
                prefixIconColor: Colors.green,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter starting point' : null,
                onAddressSelected: (address, latitude, longitude) {
                  setState(() {
                    _fromLatitude = latitude;
                    _fromLongitude = longitude;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Destination
              AddressAutocompleteField(
                controller: _toController,
                label: 'To',
                hint: 'Enter your destination',
                prefixIcon: Icons.location_on,
                prefixIconColor: Colors.red,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter destination' : null,
                onAddressSelected: (address, latitude, longitude) {
                  setState(() {
                    _toLatitude = latitude;
                    _toLongitude = longitude;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Date Selection
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Travel Date (Optional)',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
              ),

              const SizedBox(height: 12),

              // Time Selection
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Travel Time (Optional)',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: _selectTime,
              ),
              
              const SizedBox(height: 24),
              
              // Advanced Filters
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Price Range Filter
                      Text('Price Range: €${_selectedMinPrice.toStringAsFixed(0)} - €${_selectedMaxPrice.toStringAsFixed(0)}'),
                      RangeSlider(
                        values: RangeValues(_selectedMinPrice, _selectedMaxPrice),
                        min: _minPrice,
                        max: _maxPrice,
                        divisions: 50,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _selectedMinPrice = values.start;
                            _selectedMaxPrice = values.end;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Seats Filter
                      Text('Minimum Seats: $_selectedSeats'),
                      Slider(
                        value: _selectedSeats.toDouble(),
                        min: 1,
                        max: 8,
                        divisions: 7,
                        onChanged: (double value) {
                          setState(() {
                            _selectedSeats = value.toInt();
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Radius filters
                      Text('Source radius: ${_sourceRadiusKm.toStringAsFixed(1)} km'),
                      Slider(
                        value: _sourceRadiusKm,
                        min: 1,
                        max: 500,
                        divisions: 499,
                        onChanged: (double value) {
                          setState(() {
                            _sourceRadiusKm = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('Destination radius: ${_destRadiusKm.toStringAsFixed(1)} km'),
                      Slider(
                        value: _destRadiusKm,
                        min: 1,
                        max: 500,
                        divisions: 499,
                        onChanged: (double value) {
                          setState(() {
                            _destRadiusKm = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Search Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _searchTrips,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Search Rides',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'We\'ll find trips with stops near your locations',
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
