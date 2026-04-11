import 'package:flutter/material.dart';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/storage/secure_storage.dart';
import 'package:carsharing/features/auth/data/services/auth_api_service.dart';
import 'package:carsharing/features/trip/data/services/trip_api_service.dart';
import 'package:carsharing/features/user/data/services/user_api_service.dart';
import 'package:carsharing/pages/admin/seed_trips_page.dart';

/// Resolves a display name from a user map.
String _resolveName(Map<String, dynamic> u) {
  final first = (u['firstName'] ?? '').toString().trim();
  final last = (u['lastName'] ?? '').toString().trim();
  return '$first $last'.trim();
}

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
    _ManageUsersTab(),
    _AdminProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: _tabs.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Test Trips'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Users'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _AdminOverviewTab extends StatefulWidget {
  const _AdminOverviewTab();

  @override
  State<_AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<_AdminOverviewTab> {
  bool _loading = true;
  String? _error;
  List<dynamic> _trips = [];
  int _totalTrips = 0;
  bool _showUpcoming = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final service = TripApiService(DioClient());
      final result = _showUpcoming
          ? await service.adminListUpcomingTrips(size: 50)
          : await service.adminListAllTrips(size: 50);
      if (mounted) {
        setState(() {
          final content = result['content'];
          _trips = content is List ? content : [];
          _totalTrips = result['totalElements'] as int? ?? _trips.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openTripDetail(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripDetailSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Overview'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: Colors.deepPurple.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car, size: 40, color: Colors.deepPurple),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$_totalTrips',
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                  Text(_showUpcoming ? 'Upcoming Trips' : 'Total Trips',
                                      style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _FilterChip(label: 'Upcoming', selected: _showUpcoming,
                              onTap: () { setState(() => _showUpcoming = true); _load(); }),
                          const SizedBox(width: 8),
                          _FilterChip(label: 'All Trips', selected: !_showUpcoming,
                              onTap: () { setState(() => _showUpcoming = false); _load(); }),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_trips.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No trips found.', style: TextStyle(color: Colors.grey)),
                        ))
                      else
                        ..._trips.map((trip) => _AdminTripCard(
                              trip: trip as Map<String, dynamic>,
                              onTap: () => _openTripDetail(trip),
                            )),
                    ],
                  ),
                ),
    );
  }
}

// ─── Trip Card ────────────────────────────────────────────────────────────────

class _AdminTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;
  const _AdminTripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final src = trip['sourceAddress'] ?? trip['sourceLocation'] ?? {};
    final dst = trip['destinationAddress'] ?? trip['destinationLocation'] ?? {};
    final from = _addressLabel(src);
    final to = _addressLabel(dst);
    final driverId = trip['driverId'] ?? '-';
    final available = trip['availableSeats'] ?? '-';
    final status = trip['status'] ?? trip['tripStatus'] ?? '-';
    final departure = _formatDate(trip['departureTime'] ?? trip['tripStartDateTime']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.directions_car, color: Colors.deepPurple),
        title: Text('$from → $to',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Driver: $driverId\n$departure  •  Seats available: $available  •  $status',
            style: const TextStyle(fontSize: 12)),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

String _addressLabel(dynamic loc) {
  if (loc is Map) return loc['placeAddress'] ?? '${loc['latitude'] ?? ''}';
  return loc?.toString() ?? 'Unknown';
}

String _formatDate(dynamic raw) {
  if (raw == null) return '-';
  try {
    final dt = DateTime.parse(raw.toString()).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return raw.toString();
  }
}

// ─── Trip Detail Sheet ────────────────────────────────────────────────────────

class _TripDetailSheet extends StatefulWidget {
  final Map<String, dynamic> trip;
  const _TripDetailSheet({required this.trip});

  @override
  State<_TripDetailSheet> createState() => _TripDetailSheetState();
}

class _TripDetailSheetState extends State<_TripDetailSheet> {
  bool _loadingDetail = true;
  Map<String, dynamic>? _detail;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final tripId = widget.trip['tripId'] as String?;
    if (tripId == null) { setState(() => _loadingDetail = false); return; }
    final service = TripApiService(DioClient());
    final detail = await service.adminGetTrip(tripId);
    final bookings = await service.adminGetBookingsForTrip(tripId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _bookings = bookings;
        _loadingDetail = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _detail ?? widget.trip;
    final src = t['sourceAddress'] ?? t['sourceLocation'] ?? {};
    final dst = t['destinationAddress'] ?? t['destinationLocation'] ?? {};
    final totalSeats = t['totalSeats'] ?? t['offeredSeats'];
    final availableSeats = t['availableSeats'];
    final bookedSeats = (totalSeats != null && availableSeats != null)
        ? (totalSeats as int) - (availableSeats as int)
        : null;
    final price = t['pricePerSeat'];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.deepPurple),
                  const SizedBox(width: 10),
                  const Text('Trip Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_loadingDetail)
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _DetailRow(Icons.my_location, 'From', _addressLabel(src)),
                  _DetailRow(Icons.location_on, 'To', _addressLabel(dst)),
                  _DetailRow(Icons.person, 'Driver', t['driverId'] ?? '-'),
                  _DetailRow(Icons.schedule, 'Departure',
                      _formatDate(t['departureTime'] ?? t['tripStartDateTime'])),
                  if (price != null)
                    _DetailRow(Icons.euro, 'Price per seat', '€$price'),
                  if (totalSeats != null)
                    _DetailRow(Icons.event_seat, 'Seats offered', '$totalSeats'),
                  if (availableSeats != null)
                    _DetailRow(Icons.chair_alt, 'Seats available', '$availableSeats'),
                  if (bookedSeats != null)
                    _DetailRow(Icons.people, 'Seats booked', '$bookedSeats'),
                  _DetailRow(Icons.info_outline, 'Status',
                      t['status'] ?? t['tripStatus'] ?? '-'),
                  const SizedBox(height: 16),
                  // Booked passengers
                  const Text('Booked Passengers',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_loadingDetail)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_bookings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No booking data available.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._bookings.map((b) => _PassengerBookingCard(booking: b)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _PassengerBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final passengerId = booking['passengerId'] ?? '-';
    final seats = booking['requestedSeats'] ?? booking['bookedSeats'] ?? '-';
    final status = booking['status'] ?? booking['bookingStatus'] ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.person_outline, color: Colors.deepPurple, size: 20),
        title: Text(passengerId, style: const TextStyle(fontSize: 13)),
        subtitle: Text('Seats: $seats  •  Status: $status',
            style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}

// ─── Manage Users Tab ─────────────────────────────────────────────────────────

class _ManageUsersTab extends StatefulWidget {
  const _ManageUsersTab();

  @override
  State<_ManageUsersTab> createState() => _ManageUsersTabState();
}

class _ManageUsersTabState extends State<_ManageUsersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Drivers'), Tab(text: 'Passengers')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_DriversListView(), _PassengersListView()],
      ),
    );
  }
}

// ─── Drivers List ─────────────────────────────────────────────────────────────

class _DriversListView extends StatefulWidget {
  const _DriversListView();

  @override
  State<_DriversListView> createState() => _DriversListViewState();
}

class _DriversListViewState extends State<_DriversListView> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _allDrivers = [];
  String? _statusFilter; // null = all, client-side filter

  List<Map<String, dynamic>> get _filtered => _statusFilter == null
      ? _allDrivers
      : _allDrivers.where((d) => d['driverStatus'] == _statusFilter).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await UserApiService(DioClient()).adminListDrivers(size: 100);
      if (mounted) {
        setState(() {
          final content = result['content'];
          _allDrivers = content is List
              ? content.whereType<Map<String, dynamic>>().toList()
              : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _approve(String driverId) async {
    try {
      await UserApiService(DioClient()).adminApproveDriver(driverId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Driver approved'), backgroundColor: Colors.green));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _reject(String driverId) async {
    try {
      await UserApiService(DioClient()).adminRejectDriver(driverId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Driver rejected'), backgroundColor: Colors.orange));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _openDetail(Map<String, dynamic> driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(
        user: driver,
        role: 'DRIVER',
        onDeleted: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drivers = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FilterChip(label: 'All (${_allDrivers.length})', selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Pending (${_countByStatus('PENDING')})',
                  selected: _statusFilter == 'PENDING',
                  onTap: () => setState(() => _statusFilter = 'PENDING')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Active (${_countByStatus('ACTIVE')})',
                  selected: _statusFilter == 'ACTIVE',
                  onTap: () => setState(() => _statusFilter = 'ACTIVE')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Rejected (${_countByStatus('REJECTED')})',
                  selected: _statusFilter == 'REJECTED',
                  onTap: () => setState(() => _statusFilter = 'REJECTED')),
            ]),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: drivers.isEmpty
                          ? const Center(child: Text('No drivers found.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: drivers.length,
                              itemBuilder: (_, i) {
                                final d = drivers[i];
                                final driverStatus = d['driverStatus'] as String? ?? 'UNKNOWN';
                                final isPending = driverStatus == 'PENDING';
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    onTap: () => _openDetail(d),
                                    leading: CircleAvatar(
                                      backgroundColor: _statusColor(driverStatus).withValues(alpha: 0.15),
                                      child: Icon(Icons.person, color: _statusColor(driverStatus)),
                                    ),
                                    title: Text(
                                      _resolveName(d),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${d['email'] ?? '-'}\nLicense: ${d['licenseNumber'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    isThreeLine: true,
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _StatusBadge(driverStatus),
                                        if (isPending) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () => _approve(d['userId'] as String),
                                                child: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                                              ),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () => _reject(d['userId'] as String),
                                                child: const Icon(Icons.cancel, color: Colors.red, size: 22),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }

  int _countByStatus(String s) => _allDrivers.where((d) => d['driverStatus'] == s).length;
  Color _statusColor(String s) {
    switch (s) {
      case 'ACTIVE': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }
}

// ─── Passengers List ──────────────────────────────────────────────────────────

class _PassengersListView extends StatefulWidget {
  const _PassengersListView();

  @override
  State<_PassengersListView> createState() => _PassengersListViewState();
}

class _PassengersListViewState extends State<_PassengersListView> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _passengers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await UserApiService(DioClient()).adminListPassengers(size: 100);
      if (mounted) {
        setState(() {
          final content = result['content'];
          _passengers = content is List
              ? content.whereType<Map<String, dynamic>>().toList()
              : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openDetail(Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(user: p, role: 'PASSENGER', onDeleted: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _ErrorView(message: _error!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                child: _passengers.isEmpty
                    ? const Center(child: Text('No passengers found.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _passengers.length,
                        itemBuilder: (_, i) {
                          final p = _passengers[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () => _openDetail(p),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFEDE7F6),
                                child: Icon(Icons.person, color: Colors.deepPurple),
                              ),
                              title: Text(
                                _resolveName(p),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(p['email'] ?? '-',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          );
                        },
                      ),
              );
  }
}

// ─── User Detail Sheet ────────────────────────────────────────────────────────

class _UserDetailSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final String role; // 'DRIVER' or 'PASSENGER'
  final VoidCallback onDeleted;

  const _UserDetailSheet({
    required this.user,
    required this.role,
    required this.onDeleted,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  List<Map<String, dynamic>> _vehicles = [];
  bool _loadingVehicles = false;
  bool _deleting = false;
  Map<String, dynamic>? _fullProfile; // fetched from /api/users/{id} for accurate name

  @override
  void initState() {
    super.initState();
    _loadFullProfile();
    if (widget.role == 'DRIVER') _loadVehicles();
  }

  String get _userId =>
      widget.user['userId'] as String? ?? widget.user['email'] as String? ?? '';

  Future<void> _loadFullProfile() async {
    final profile = await UserApiService(DioClient()).getUserById(_userId);
    if (mounted && profile != null) setState(() => _fullProfile = profile);
  }

  Future<void> _loadVehicles() async {
    setState(() => _loadingVehicles = true);
    final v = await UserApiService(DioClient()).getVehiclesByUserId(_userId);
    if (mounted) setState(() { _vehicles = v; _loadingVehicles = false; });
  }

  Future<void> _confirmDelete() async {
    final userId = widget.user['userId'] as String? ?? '';
    final name = _resolveName(widget.user);
    final userType = widget.user['userType'] ?? widget.user['role'] ?? '';

    // Block admin deletion
    if (userType == 'ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin accounts cannot be deleted.'), backgroundColor: Colors.red));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $name? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      final service = UserApiService(DioClient());
      if (widget.role == 'DRIVER') {
        await service.adminDeleteDriver(userId);
      } else {
        await service.adminDeletePassenger(userId);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onDeleted();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Merge: prefer full profile (has accurate names) over the list item data
    final u = {...widget.user, ...?_fullProfile};
    final driverStatus = u['driverStatus'] as String?;
    final createdAt = _formatDate(u['createdAt']);
    final userType = u['userType'] ?? u['role'] ?? widget.role;
    final isAdmin = userType == 'ADMIN';

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Avatar + role header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.deepPurple.shade50,
                    child: const Icon(Icons.person, color: Colors.deepPurple, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Row(
                      children: [
                        Text(widget.role,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        if (driverStatus != null) ...[
                          const SizedBox(width: 10),
                          _StatusBadge(driverStatus),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _DetailRow(Icons.person, 'First Name', u['firstName']?.toString().isNotEmpty == true ? u['firstName'].toString() : (_fullProfile == null ? 'Loading…' : '-')),
                  _DetailRow(Icons.person_outline, 'Last Name', u['lastName']?.toString().isNotEmpty == true ? u['lastName'].toString() : (_fullProfile == null ? 'Loading…' : '-')),
                  _DetailRow(Icons.email, 'Email', u['email'] ?? '-'),
                  _DetailRow(Icons.phone, 'Phone', u['phoneNumber'] ?? '-'),
                  _DetailRow(Icons.cake, 'Age', u['age']?.toString() ?? '-'),
                  _DetailRow(Icons.badge, 'User ID', u['userId'] ?? '-'),
                  _DetailRow(Icons.calendar_today, 'Joined', createdAt),
                  if (widget.role == 'DRIVER') ...[
                    _DetailRow(Icons.credit_card, 'License', u['licenseNumber'] ?? '-'),
                    const SizedBox(height: 14),
                    const Text('Registered Vehicles',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_loadingVehicles)
                      const Center(child: CircularProgressIndicator())
                    else if (_vehicles.isEmpty)
                      const Text('No vehicles registered.', style: TextStyle(color: Colors.grey))
                    else
                      ..._vehicles.map((v) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.directions_car, color: Colors.deepPurple, size: 20),
                              title: Text(v['text'] ?? v['vehicleName'] ?? '-'),
                              subtitle: Text('Seats: ${v['seatingCapacity'] ?? '-'}  •  ${v['value'] ?? ''}'),
                            ),
                          )),
                  ],
                  const SizedBox(height: 20),
                  if (!isAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _deleting ? null : _confirmDelete,
                        icon: _deleting
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.delete_forever),
                        label: const Text('Remove User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

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
              child: const Icon(Icons.admin_panel_settings, size: 52, color: Colors.deepPurple),
            ),
            const SizedBox(height: 16),
            Text(_email.isNotEmpty ? _email : 'Admin',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(20)),
              child: const Text('ADMIN',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthApiService().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'ACTIVE': color = Colors.green; break;
      case 'PENDING': color = Colors.orange; break;
      case 'REJECTED': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
