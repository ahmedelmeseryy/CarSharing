import 'package:carsharing/constants/german_cities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final _formKey = GlobalKey<FormState>();
  String? _from;
  String? _to;
  DateTime? _date;
  TimeOfDay? _time;
  int _seats = 1;
  double _price = 0.0;

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a New Trip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownSearch<String>(
                popupProps: const PopupProps.menu(showSearchBox: true),
                items: germanCities,
                selectedItem: _from,
                onChanged: (value) {
                  setState(() {
                    _from = value;
                  });
                },
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "From",
                    border: OutlineInputBorder(),
                  ),
                ),
                onSaved: (value) => _from = value,
                validator: (value) =>
                    value == null ? 'Please select a starting point' : null,
              ),
              const SizedBox(height: 16),
              DropdownSearch<String>(
                popupProps: const PopupProps.menu(showSearchBox: true),
                items: germanCities,
                selectedItem: _to,
                onChanged: (value) {
                  setState(() {
                    _to = value;
                  });
                },
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "To",
                    border: OutlineInputBorder(),
                  ),
                ),
                onSaved: (value) => _to = value,
                validator: (value) =>
                    value == null ? 'Please select a destination' : null,
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
                child: const Text('Add Trip'),
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
    print('Form submission started');
    print('From: $_from');
    print('To: $_to');
    print('Date: $_date');
    print('Time: $_time');
    print('Seats: $_seats');
    print('Price: $_price');
    
    if (_formKey.currentState!.validate()) {
      print('Form validation passed');
      _formKey.currentState!.save();
      
      print('After save - From: $_from');
      print('After save - To: $_to');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user found');
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
        
        print('Driver name: $driverName');

        final dateTime = DateTime(
            _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

        final tripData = {
          'from': _from,
          'to': _to,
          'date': Timestamp.fromDate(dateTime),
          'seats': _seats,
          'price': _price,
          'driverId': user.uid,
          'driverName':
              driverName.trim().isNotEmpty ? driverName.trim() : 'Unnamed Driver',
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        print('Trip data to save: $tripData');

        await FirebaseFirestore.instance.collection('trips').add(tripData);
        
        print('Trip saved successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip added successfully!')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        print('Error saving trip: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding trip: $e')),
        );
      }
    } else {
      print('Form validation failed');
    }
  }
} 