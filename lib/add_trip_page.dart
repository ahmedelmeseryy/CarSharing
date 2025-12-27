import 'package:carsharing/models/trip_stop.dart';
import 'package:carsharing/widgets/address_autocomplete_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Duplicate imports removed
// Removed unused imports to clean analyzer warnings

class AddTripPage extends StatefulWidget {
  final Map<String, dynamic>? templateData; // For loading from template

  const AddTripPage({super.key, this.templateData});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Address fields (exact addresses)
  final _fromAddressController = TextEditingController();
  final _toAddressController = TextEditingController();
  double? _fromLatitude;
  double? _fromLongitude;
  double? _toLatitude;
  double? _toLongitude;
  
  // Stops
  List<TripStop> _stops = [];
  final Map<int, TextEditingController> _stopControllers = {};
  
  DateTime? _date;
  TimeOfDay? _time;
  int _seats = 1;
  double _price = 0.0;
  int? _estimatedDurationMinutes; // Estimated trip duration

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load template data if provided
    if (widget.templateData != null) {
      _loadTemplateData(widget.templateData!);
    }
  }

  void _loadTemplateData(Map<String, dynamic> template) {
    _fromAddressController.text = template['from'] ?? template['fromAddress'] ?? '';
    _toAddressController.text = template['to'] ?? template['toAddress'] ?? '';
    _seats = template['seats'] ?? 1;
    _price = (template['price'] ?? 0.0).toDouble();
    
    if (template['stops'] != null) {
      final stopsList = template['stops'] as List;
      _stops = stopsList.map((s) => TripStop.fromMap(s)).toList();
      for (var i = 0; i < _stops.length; i++) {
        _stopControllers[i] = TextEditingController(text: _stops[i].address);
      }
    }
    
    if (template['date'] != null) {
      _date = (template['date'] as Timestamp).toDate();
      _dateController.text = DateFormat.yMd().format(_date!);
    }
  }

  @override
  void dispose() {
    _fromAddressController.dispose();
    _toAddressController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    for (var controller in _stopControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a New Trip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save as Template',
            onPressed: _saveAsTemplate,
          ),
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
                  _calculateEstimatedTime();
                },
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 16),
              
              // Stops Section
              _buildStopsSection(),
              
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
                  _calculateEstimatedTime();
                },
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 16),
              
              // Estimated Time Display
              if (_estimatedDurationMinutes != null)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Estimated Duration: ${_formatDuration(_estimatedDurationMinutes!)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                decoration: const InputDecoration(
                  labelText: 'Available Seats',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: '1',
                onSaved: (value) => _seats = int.tryParse(value ?? '1') ?? 1,
                validator: (value) {
                  if (value == null ||
                      int.tryParse(value) == null ||
                      int.parse(value) <= 0) {
                    return 'Please enter a valid number of seats';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Price per Seat (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onSaved: (value) =>
                    _price = double.tryParse(value ?? '0.0') ?? 0.0,
                validator: (value) {
                  if (value == null ||
                      double.tryParse(value) == null ||
                      double.parse(value) < 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Add Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Intermediate Stops (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Stop'),
              onPressed: _addStop,
            ),
          ],
        ),
        if (_stops.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Add stops where passengers can get on/off',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ...List.generate(_stops.length, (index) {
          return _buildStopItem(index);
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStopItem(int index) {
    final controller = _stopControllers[index] ?? TextEditingController();
    if (!_stopControllers.containsKey(index)) {
      _stopControllers[index] = controller;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: AddressAutocompleteField(
                controller: controller,
                label: 'Stop ${index + 1}',
                hint: 'Enter stop address',
                prefixIcon: Icons.location_on,
                prefixIconColor: Colors.orange,
                onAddressSelected: (address, latitude, longitude) {
                  _stops[index] = TripStop(
                    address: address,
                    order: index + 1,
                    latitude: latitude,
                    longitude: longitude,
                  );
                  _calculateEstimatedTime();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeStop(index),
            ),
          ],
        ),
      ),
    );
  }

  void _addStop() {
    setState(() {
      final newOrder = _stops.length + 1;
      _stops.add(TripStop(
        address: '',
        order: newOrder,
      ));
      _stopControllers[_stops.length - 1] = TextEditingController();
    });
    _calculateEstimatedTime();
  }

  void _removeStop(int index) {
    setState(() {
      _stopControllers[index]?.dispose();
      _stopControllers.remove(index);
      _stops.removeAt(index);
      
      // Reorder remaining stops
      for (var i = 0; i < _stops.length; i++) {
        _stops[i] = TripStop(
          address: _stops[i].address,
          order: i + 1,
          latitude: _stops[i].latitude,
          longitude: _stops[i].longitude,
        );
      }
      
      // Rebuild controllers map
      final newControllers = <int, TextEditingController>{};
      for (var i = 0; i < _stops.length; i++) {
        if (_stopControllers.containsKey(i + index + 1)) {
          newControllers[i] = _stopControllers[i + index + 1]!;
        } else {
          newControllers[i] = TextEditingController(text: _stops[i].address);
        }
      }
      _stopControllers.clear();
      _stopControllers.addAll(newControllers);
    });
    _calculateEstimatedTime();
  }

  void _calculateEstimatedTime() {
    // Basic estimation: ~1 hour per 100km, ~30 min per stop
    // This is a placeholder - in production, use Maps API for accurate calculation
    if (_fromAddressController.text.isNotEmpty && 
        _toAddressController.text.isNotEmpty) {
      // Simple heuristic: assume average distance
      int baseMinutes = 120; // 2 hours base
      int stopMinutes = _stops.length * 15; // 15 min per stop
      setState(() {
        _estimatedDurationMinutes = baseMinutes + stopMinutes;
      });
    } else {
      setState(() {
        _estimatedDurationMinutes = null;
      });
    }
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Future<void> _saveAsTemplate() async {
    if (_fromAddressController.text.isEmpty || _toAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in at least origin and destination to save as template'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final templateData = {
        'from': _fromAddressController.text,
        'to': _toAddressController.text,
        'stops': _stops.map((s) => s.toMap()).toList(),
        'seats': _seats,
        'price': _price,
        'savedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trip_templates')
          .add(templateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip saved as template!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving template: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Validation checks
      if (_fromAddressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a starting address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_toAddressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a destination address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_date == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_time == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time'),
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

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data();
        final driverName =
            (userData?['name'] ?? '') + ' ' + (userData?['surname'] ?? '');

        final dateTime = DateTime(
            _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

        // Calculate estimated arrival time at destination
        final estimatedArrival = _estimatedDurationMinutes != null
            ? dateTime.add(Duration(minutes: _estimatedDurationMinutes!))
            : null;

        // Prepare stops data (update with current controller values)
        final stopsData = <Map<String, dynamic>>[];
        for (var i = 0; i < _stops.length; i++) {
          final controller = _stopControllers[i];
          if (controller != null && controller.text.isNotEmpty) {
            stopsData.add({
              'address': controller.text,
              'order': i + 1,
              'latitude': _stops[i].latitude,
              'longitude': _stops[i].longitude,
            });
          }
        }

        final tripData = {
          // Legacy fields for backward compatibility
          'from': _fromAddressController.text,
          'to': _toAddressController.text,
          
          // New enhanced fields
          'fromAddress': _fromAddressController.text,
          'toAddress': _toAddressController.text,
          'fromLatitude': _fromLatitude,
          'fromLongitude': _fromLongitude,
          'toLatitude': _toLatitude,
          'toLongitude': _toLongitude,
          'stops': stopsData,
          'estimatedDurationMinutes': _estimatedDurationMinutes,
          'estimatedArrivalTime': estimatedArrival != null
              ? Timestamp.fromDate(estimatedArrival)
              : null,
          
          // Common fields
          'date': Timestamp.fromDate(dateTime),
          'seats': _seats,
          'price': _price,
          'driverId': user.uid,
          'driverName':
              driverName.trim().isNotEmpty ? driverName.trim() : 'Unnamed Driver',
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('trips').add(tripData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      } catch (e) {
        print('Error saving trip: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 