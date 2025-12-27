import 'package:carsharing/widgets/address_autocomplete_field.dart';
import 'package:carsharing/services/route_matching_service.dart';
import 'package:carsharing/pages/user/trip_search_results_page.dart';
import 'package:carsharing/widgets/map_location_picker.dart';
import 'package:carsharing/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripSearchPage extends StatefulWidget {
  const TripSearchPage({super.key});

  @override
  State<TripSearchPage> createState() => _TripSearchPageState();
}

class _TripSearchPageState extends State<TripSearchPage> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  double? _fromLatitude;
  double? _fromLongitude;
  double? _toLatitude;
  double? _toLongitude;
  
  DateTime? _selectedDate;
  final _dateController = TextEditingController();
  
  // Advanced search filters
  double _minPrice = 0;
  double _maxPrice = 500;
  double _selectedMinPrice = 0;
  double _selectedMaxPrice = 500;
  int _selectedSeats = 1;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
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

      // Check if we have coordinates
      if (_fromLatitude == null || _fromLongitude == null ||
          _toLatitude == null || _toLongitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select addresses from the suggestions for accurate matching'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        // Still proceed with search, but matching will be less accurate
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Find matching trips
        final matches = await RouteMatchingService.findMatchingTrips(
          userFromLat: _fromLatitude ?? 0.0,
          userFromLng: _fromLongitude ?? 0.0,
          userToLat: _toLatitude ?? 0.0,
          userToLng: _toLongitude ?? 0.0,
          preferredDate: _selectedDate,
          searchRadius: 10.0, // 10 km radius
        );

        // Apply filters to the matches
        final filteredMatches = matches.where((match) {
          // Filter by price
          final tripPrice = double.tryParse(match.tripData['price'].toString()) ?? 0;
          if (tripPrice < _selectedMinPrice || tripPrice > _selectedMaxPrice) {
            return false;
          }
          
          // Filter by available seats
          final availableSeats = int.tryParse(match.tripData['availableSeats'].toString()) ?? 0;
          if (availableSeats < _selectedSeats) {
            return false;
          }
          
          return true;
        }).toList();

        if (!context.mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (filteredMatches.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No matching trips found. Try adjusting your search or filters.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          // Navigate to results page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripSearchResultsPage(
                matches: filteredMatches,
                searchFrom: _fromController.text,
                searchTo: _toController.text,
              ),
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context); // Close loading dialog
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
