import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carsharing/pages/admin/seed_trips_page.dart';
import 'package:carsharing/features/trip/data/services/trip_firestore_service.dart';

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
  int _userCount = 0;
  int _driverCount = 0;
  int _adminCount = 0;
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      int users = 0, drivers = 0, admins = 0;
      for (final doc in snapshot.docs) {
        final role = doc.data()['role'] as String? ?? 'user';
        if (role == 'driver') {
          drivers++;
        } else if (role == 'admin') {
          admins++;
        } else {
          users++;
        }
      }
      setState(() {
        _userCount = users;
        _driverCount = drivers;
        _adminCount = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'User Statistics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Passengers',
                          count: _userCount,
                          icon: Icons.person,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Drivers',
                          count: _driverCount,
                          icon: Icons.drive_eta,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Admins',
                          count: _adminCount,
                          icon: Icons.admin_panel_settings,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        {'label': 'All Users', 'value': 'all', 'icon': Icons.people},
                        {'label': 'Passengers', 'value': 'user', 'icon': Icons.person},
                        {'label': 'Drivers', 'value': 'driver', 'icon': Icons.drive_eta},
                        {'label': 'Admins', 'value': 'admin', 'icon': Icons.admin_panel_settings},
                      ].map((f) {
                        final isSelected = _selectedFilter == f['value'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f['label'] as String),
                            avatar: Icon(f['icon'] as IconData,
                                size: 16,
                                color: isSelected ? Colors.white : Colors.deepPurple),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedFilter = f['value'] as String),
                            selectedColor: Colors.deepPurple,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            checkmarkColor: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _UserListSection(filter: _selectedFilter),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _UserListSection extends StatelessWidget {
  final String filter;
  const _UserListSection({required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No users found.');
        }
        final docs = snapshot.data!.docs.where((doc) {
          if (filter == 'all') return true;
          final role = (doc.data() as Map<String, dynamic>)['role'] as String? ?? 'user';
          return role == filter;
        }).toList();
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No ${filter == 'all' ? 'users' : '${filter}s'} found.')),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final role = data['role'] as String? ?? 'user';
            final name = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
            final email = data['email'] as String? ?? '';
            final displayName = name.isEmpty ? email : name;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _roleColor(role).withValues(alpha: 0.15),
                  child: Icon(_roleIcon(role), color: _roleColor(role)),
                ),
                title: Text(displayName),
                subtitle: Text(email),
                trailing: Chip(
                  label: Text(
                    role.toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: _roleColor(role),
                  padding: EdgeInsets.zero,
                ),
                onTap: () => _showUserOptions(context, doc.id, displayName, email, role),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showUserOptions(BuildContext context, String uid, String name, String email, String role) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(email, style: const TextStyle(fontSize: 12)),
            ),
            const Divider(height: 1),
            if (role == 'admin')
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Admin accounts cannot be deleted.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, uid, name, email);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String uid, String name, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this user?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('users').doc(uid).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name has been deleted.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'driver':
        return Colors.green;
      case 'admin':
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'driver':
        return Icons.drive_eta;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }
}

// ─── Manage User Data Tab ────────────────────────────────────────────────────

class _ManageUserDataTab extends StatefulWidget {
  const _ManageUserDataTab();

  @override
  State<_ManageUserDataTab> createState() => _ManageUserDataTabState();
}

class _ManageUserDataTabState extends State<_ManageUserDataTab> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    TripFirestoreService().autoMarkCompletedTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage User Data'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          final allDocs = snapshot.data!.docs;
          final filtered = allDocs.where((doc) {
            if (_selectedFilter == 'all') return true;
            final role = (doc.data() as Map<String, dynamic>)['role'] as String? ?? 'user';
            return role == _selectedFilter;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      {'label': 'All Users', 'value': 'all', 'icon': Icons.people},
                      {'label': 'Passengers', 'value': 'user', 'icon': Icons.person},
                      {'label': 'Drivers', 'value': 'driver', 'icon': Icons.drive_eta},
                      {'label': 'Admins', 'value': 'admin', 'icon': Icons.admin_panel_settings},
                    ].map((f) {
                      final isSelected = _selectedFilter == f['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f['label'] as String),
                          avatar: Icon(f['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.deepPurple),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = f['value'] as String),
                          selectedColor: Colors.deepPurple,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_selectedFilter == 'all' ? 'users' : '${_selectedFilter}s'} found.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final data = filtered[index].data() as Map<String, dynamic>;
                          final uid = filtered[index].id;
                          final name = '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
                          final email = data['email'] as String? ?? '';
                          final role = data['role'] as String? ?? 'user';
                          return _UserTripExpansionTile(
                            uid: uid,
                            displayName: name.isEmpty ? email : name,
                            email: email,
                            role: role,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserTripExpansionTile extends StatefulWidget {
  final String uid;
  final String displayName;
  final String email;
  final String role;

  const _UserTripExpansionTile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
  });

  @override
  State<_UserTripExpansionTile> createState() => _UserTripExpansionTileState();
}

class _UserTripExpansionTileState extends State<_UserTripExpansionTile> {
  bool _expanded = false;
  List<Map<String, dynamic>>? _trips;
  bool _loading = false;

  Color get _roleColor {
    switch (widget.role) {
      case 'driver': return Colors.green;
      case 'admin': return Colors.deepPurple;
      default: return Colors.blue;
    }
  }

  Future<void> _loadTrips() async {
    if (_trips != null) return; // already loaded
    setState(() => _loading = true);

    final db = FirebaseFirestore.instance;
    final results = <Map<String, dynamic>>[];

    // Trips as driver
    final asDriver = await db
        .collection('trips')
        .where('driverId', isEqualTo: widget.uid)
        .get();
    for (final doc in asDriver.docs) {
      results.add({...doc.data(), '_tripId': doc.id, '_asRole': 'driver'});
    }

    // Trips as passenger
    final asPassenger = await db
        .collection('trips')
        .where('joinedRidersId', arrayContains: widget.uid)
        .get();
    for (final doc in asPassenger.docs) {
      // avoid duplicates (a driver who also joined their own trip)
      if (!results.any((t) => t['_tripId'] == doc.id)) {
        results.add({...doc.data(), '_tripId': doc.id, '_asRole': 'passenger'});
      }
    }

    // Sort by date descending
    results.sort((a, b) {
      final aDate = (a['date'] as Timestamp?)?.toDate() ?? DateTime(0);
      final bDate = (b['date'] as Timestamp?)?.toDate() ?? DateTime(0);
      return bDate.compareTo(aDate);
    });

    setState(() {
      _trips = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor.withValues(alpha: 0.15),
          child: Icon(
            widget.role == 'driver'
                ? Icons.drive_eta
                : widget.role == 'admin'
                    ? Icons.admin_panel_settings
                    : Icons.person,
            color: _roleColor,
          ),
        ),
        title: Text(widget.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(widget.email, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                widget.role.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: _roleColor,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
        onExpansionChanged: (expanded) {
          setState(() => _expanded = expanded);
          if (expanded) _loadTrips();
        },
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_trips == null || _trips!.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('No trips found for this user.', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._trips!.map((trip) => _TripRow(trip: trip)),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    final from = trip['from'] as String? ?? '?';
    final to = trip['to'] as String? ?? '?';
    final date = (trip['date'] as Timestamp?)?.toDate();
    final price = trip['price'];
    final seats = trip['seats'];
    final asRole = trip['_asRole'] as String? ?? '';
    final status = trip['status'] as String? ?? 'unknown';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            asRole == 'driver' ? Icons.drive_eta : Icons.airline_seat_recline_normal,
            size: 18,
            color: asRole == 'driver' ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from → $to',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                      : 'No date',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (price != null)
                Text('€${price.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              if (seats != null)
                Text('$seats seats', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status == 'available'
                      ? Colors.green.shade100
                      : status == 'cancelled'
                          ? Colors.red.shade100
                          : status == 'completed'
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    color: status == 'available'
                        ? Colors.green.shade800
                        : status == 'cancelled'
                            ? Colors.red.shade800
                            : status == 'completed'
                                ? Colors.blue.shade800
                                : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Profile Tab ─────────────────────────────────────────────────────────────

class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
              child:
                  const Icon(Icons.admin_panel_settings, size: 52, color: Colors.deepPurple),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? 'Admin',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
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
