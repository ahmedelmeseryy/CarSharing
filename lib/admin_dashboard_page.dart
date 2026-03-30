import 'package:flutter/material.dart';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/storage/secure_storage.dart';
import 'package:carsharing/features/auth/data/services/auth_api_service.dart';
import 'package:carsharing/features/trip/data/services/trip_api_service.dart';
import 'package:carsharing/features/user/data/services/user_api_service.dart';
import 'package:carsharing/pages/admin/seed_trips_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = const [
    _AdminOverviewTab(),
    SeedTripsPage(),
    _ManageUserDataTab(),
    _AdminProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: _tabs.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storage),
              label: 'Test Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt),
              label: 'Manage Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Overview Tab ────────────────────────────────────────────────────────────

class _AdminOverviewTab extends StatefulWidget {
  const _AdminOverviewTab();

  @override
  State<_AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<_AdminOverviewTab> {
  bool _loading = true;
  String? _error;
  int _tripCount = 0;
  List<dynamic> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = TripApiService(DioClient());
      // Search from central Germany with a large radius to get all available trips
      final result = await service.searchNearSource(
        sourceLat: 51.1657,
        sourceLon: 10.4515,
        radiusKm: 1000,
      );
      if (mounted) {
        setState(() {
          _trips = result.data ?? [];
          _tripCount = _trips.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Overview'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text('Failed to load trips: $_error',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _loadTrips,
                            child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats card
                      Card(
                        color: Colors.deepPurple.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car,
                                  size: 40, color: Colors.deepPurple),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_tripCount',
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple),
                                  ),
                                  const Text('Active Trips in System',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Active Trips',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_trips.isEmpty)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No active trips found.',
                              style: TextStyle(color: Colors.grey)),
                        ))
                      else
                        ..._trips.map((trip) => _TripCard(trip: trip)),
                    ],
                  ),
                ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final dynamic trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final from = trip.sourceAddress.placeAddress ?? 'Unknown';
    final to = trip.destinationAddress.placeAddress ?? 'Unknown';
    final driverId = trip.driverId ?? '-';
    final available = trip.availableSeats ?? 0;
    final total = trip.totalSeats ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.directions_car, color: Colors.deepPurple),
        title: Text('$from → $to',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          'Driver: $driverId\nSeats: $available / $total available',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
      ),
    );
  }
}

// ─── Manage User Data Tab ────────────────────────────────────────────────────

class _ManageUserDataTab extends StatefulWidget {
  const _ManageUserDataTab();

  @override
  State<_ManageUserDataTab> createState() => _ManageUserDataTabState();
}

class _ManageUserDataTabState extends State<_ManageUserDataTab> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookupUser() async {
    final userId = _controller.text.trim();
    if (userId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _userProfile = null;
      _vehicles = [];
    });
    try {
      final service = UserApiService(DioClient());
      final profile = await service.getUserById(userId);
      final vehicles = await service.getVehiclesByUserId(userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _vehicles = vehicles;
          _loading = false;
          if (profile == null) _error = 'User not found.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lookup failed: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'User ID',
                      hintText: 'Paste user UUID here',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _lookupUser(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _lookupUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Look up'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),

            // User profile
            if (_userProfile != null) ...[
              const Text('User Profile',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ProfileRow(
                          Icons.badge, 'ID',
                          _userProfile!['userId'] ?? '-'),
                      _ProfileRow(
                          Icons.person, 'Name',
                          '${_userProfile!['firstName'] ?? ''} ${_userProfile!['lastName'] ?? ''}'.trim()),
                      _ProfileRow(
                          Icons.email, 'Email',
                          _userProfile!['email'] ?? '-'),
                      _ProfileRow(
                          Icons.phone, 'Phone',
                          _userProfile!['phoneNumber'] ?? '-'),
                      _ProfileRow(
                          Icons.cake, 'Age',
                          _userProfile!['age']?.toString() ?? '-'),
                      _ProfileRow(
                          Icons.work, 'Role',
                          _userProfile!['role'] ?? '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Vehicles
              const Text('Registered Vehicles',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_vehicles.isEmpty)
                const Text('No vehicles registered.',
                    style: TextStyle(color: Colors.grey))
              else
                ..._vehicles.map((v) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.directions_car,
                            color: Colors.deepPurple),
                        title: Text(v['text'] ?? '-'),
                        subtitle: Text(
                            'Seats: ${v['seatingCapacity'] ?? '-'}'),
                      ),
                    )),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text('$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// ─── Profile Tab ─────────────────────────────────────────────────────────────

class _AdminProfileTab extends StatefulWidget {
  const _AdminProfileTab();

  @override
  State<_AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<_AdminProfileTab> {
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final email = await TokenStorage().getUserEmail();
    if (mounted) setState(() => _email = email ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.deepPurple.shade100,
              child: const Icon(Icons.admin_panel_settings,
                  size: 52, color: Colors.deepPurple),
            ),
            const SizedBox(height: 16),
            Text(
              _email.isNotEmpty ? _email : 'Admin',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthApiService().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
