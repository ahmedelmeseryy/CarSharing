import 'package:flutter/material.dart';
import 'package:carsharing/core/storage/secure_storage.dart';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/features/auth/data/services/auth_api_service.dart';
import 'package:carsharing/features/auth/presentation/change_password_page.dart';
import 'package:carsharing/features/driver/presentation/register_vehicle_page.dart';
import 'package:carsharing/features/user/data/services/user_api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = true;
  String _userRole = 'user';
  String _email = '';
  List<Map<String, dynamic>> _vehicles = [];
  bool _vehiclesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final storage = TokenStorage();
    _nameController.text = await storage.getUserName() ?? '';
    _surnameController.text = await storage.getUserSurname() ?? '';
    _ageController.text = await storage.getUserAge() ?? '';
    _phoneController.text = await storage.getUserPhone() ?? '';
    _userRole = await storage.getUserRole() ?? 'user';
    _email = await storage.getUserEmail() ?? '';
    if (_userRole == 'driver') {
      await _loadVehicles();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadVehicles() async {
    setState(() => _vehiclesLoading = true);
    try {
      final userId = await TokenStorage().getUserId() ?? '';
      final vehicles = await UserApiService(DioClient()).getVehiclesByUserId(userId);
      setState(() {
        _vehicles = vehicles;
        _vehiclesLoading = false;
      });
    } catch (_) {
      setState(() => _vehiclesLoading = false);
    }
  }

  void _showVehicleDetails(Map<String, dynamic> v) {
    final displayText = v['text'] as String? ?? 'Unknown';
    final plateOrId = v['value'] as String? ?? 'N/A';
    final seats = v['seatingCapacity'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vehicle Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.directions_car, 'Name / Color', displayText),
            const SizedBox(height: 12),
            _detailRow(Icons.credit_card, 'Plate Number', plateOrId),
            const SizedBox(height: 12),
            _detailRow(Icons.event_seat, 'Seating Capacity', '$seats seats'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await TokenStorage().saveUserProfile(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          age: _ageController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _logout(BuildContext context) async {
    await AuthApiService().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.blue),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Icon(Icons.person, size: 38, color: Colors.blue),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_nameController.text} ${_surnameController.text}',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(_email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.blue),
                                  onPressed: _isEditing ? _save : _toggleEdit,
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Name'),
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _surnameController,
                              decoration: const InputDecoration(labelText: 'Surname'),
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(labelText: 'Age'),
                              keyboardType: TextInputType.number,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(labelText: 'Phone'),
                              keyboardType: TextInputType.phone,
                              enabled: _isEditing,
                            ),
                            if (_userRole == 'driver') ...[
                              const Divider(height: 32),
                              const Text(
                                'Driver Information',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Feature not yet implemented.')),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Upload Driver License'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'My Vehicles (${_vehicles.length}/1)',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  if (_vehiclesLoading)
                                    const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.refresh, size: 20),
                                      onPressed: _loadVehicles,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (!_vehiclesLoading && _vehicles.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'No vehicles registered. Register one to create trips.',
                                          style: TextStyle(fontSize: 13, color: Colors.orange),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...(_vehicles.map((v) {
                                  final displayText = v['text'] as String? ?? 'Unknown';
                                  final plateOrId = v['value'] as String? ?? '';
                                  final seats = v['seatingCapacity'] ?? '?';
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.directions_car, color: Colors.blue),
                                      title: Text(displayText),
                                      subtitle: Text('Plate: $plateOrId • $seats seats'),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.red.shade200),
                                        tooltip: 'Delete vehicle',
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Contact admin to remove vehicle'),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        },
                                      ),
                                      onTap: () => _showVehicleDetails(v),
                                    ),
                                  );
                                })),
                              const SizedBox(height: 12),
                              if (_vehicles.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.amber, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Vehicle registration is temporarily limited to 1 per driver.',
                                          style: TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              OutlinedButton.icon(
                                onPressed: _vehicles.isNotEmpty
                                    ? null
                                    : () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const RegisterVehiclePage(),
                                          ),
                                        );
                                        _loadVehicles();
                                      },
                                icon: const Icon(Icons.add),
                                label: Text(
                                  _vehicles.isNotEmpty
                                      ? 'Vehicle Limit Reached (1/1)'
                                      : 'Register Vehicle',
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  foregroundColor: _vehicles.isNotEmpty ? Colors.grey : Colors.blue,
                                  side: BorderSide(
                                    color: _vehicles.isNotEmpty ? Colors.grey : Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                                );
                              },
                              icon: const Icon(Icons.lock_outline),
                              label: const Text('Change Password'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
