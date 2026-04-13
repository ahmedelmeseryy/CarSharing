import 'package:flutter/material.dart';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/storage/secure_storage.dart';
import 'package:carsharing/features/user/data/services/user_api_service.dart';

class RegisterVehiclePage extends StatefulWidget {
  final VoidCallback? onRegistered;

  const RegisterVehiclePage({super.key, this.onRegistered});

  @override
  State<RegisterVehiclePage> createState() => _RegisterVehiclePageState();
}

class _RegisterVehiclePageState extends State<RegisterVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _seatingCapacityController = TextEditingController(text: '4');
  String _vehicleType = 'sedan';
  bool _isLoading = false;

  static const _vehicleTypes = ['sedan', 'suv', 'hatchback', 'minivan'];

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _vehicleNumberController.dispose();
    _vehicleColorController.dispose();
    _seatingCapacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add your vehicle details so you can offer rides.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _vehicleNameController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Name / Model',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Toyota Corolla',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter vehicle name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: 'License Plate / Vehicle Number',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., ABC-1234',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter vehicle number' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  border: OutlineInputBorder(),
                ),
                items: _vehicleTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _vehicleType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleColorController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Color',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Silver',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter vehicle color' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seatingCapacityController,
                decoration: const InputDecoration(
                  labelText: 'Seating Capacity',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 4',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter seating capacity';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1 || n > 20) return 'Enter a valid number (1-20)';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Register Vehicle',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = await TokenStorage().getUserId();
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final userService = UserApiService(DioClient());
      await userService.registerVehicle(
        userId: userId,
        vehicleName: _vehicleNameController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim().toUpperCase(),
        vehicleType: _vehicleType,
        vehicleColor: _vehicleColorController.text.trim(),
        seatingCapacity: _seatingCapacityController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      if (widget.onRegistered != null) {
        widget.onRegistered!();
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }
}
