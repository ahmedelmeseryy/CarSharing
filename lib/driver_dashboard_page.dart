import 'package:flutter/material.dart';
import 'driver_profile_page.dart';
import 'add_trip_page.dart';
import 'pages/driver/driver_trip_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carsharing/main.dart'; // For ProfilePage
import 'package:carsharing/ride_detail_page.dart';
import 'package:intl/intl.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const DriverTripsPage(),
    const BookingsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: _widgetOptions.elementAt(_selectedIndex),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddTripPage()),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.drive_eta),
              label: 'My Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class DriverTripsPage extends StatefulWidget {
  const DriverTripsPage({super.key});

  @override
  _DriverTripsPageState createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
  final user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _getDriverTripsStream() {
    if (user == null) {
      return Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('trips')
        .where('driverId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _deleteTrip(String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('trips').doc(tripId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Created Trips'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getDriverTripsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have not created any trips yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final trips = snapshot.data!.docs;

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final tripDoc = trips[index];
              final trip = tripDoc.data() as Map<String, dynamic>;
              
              String formattedDate = 'N/A';
              if (trip['date'] is Timestamp) {
                formattedDate = DateFormat.yMd().format((trip['date'] as Timestamp).toDate());
              }
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${trip['from']} to ${trip['to']}'),
                  subtitle: Text('€${trip['price']} - $formattedDate'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTrip(tripDoc.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverTripDetailsPage(
                          tripId: tripDoc.id,
                          tripData: trip,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _getDriverBookingsStream() {
    if (user == null) {
      print('Driver not logged in for bookings');
      return Stream.empty();
    }
    print('Loading bookings for driver: ${user!.uid}');
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('driverId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getDriverBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No one has booked your trips yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final bookingData = booking.data() as Map<String, dynamic>;
              
              String formattedDate = 'N/A';
              if (bookingData['createdAt'] is Timestamp) {
                formattedDate = DateFormat.yMd().format((bookingData['createdAt'] as Timestamp).toDate());
              }

              String tripDate = 'N/A';
              if (bookingData['tripDate'] is Timestamp) {
                tripDate = DateFormat.yMd().format((bookingData['tripDate'] as Timestamp).toDate());
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, size: 30, color: Colors.blue),
                  ),
                  title: Text(
                    '${bookingData['tripFrom']} to ${bookingData['tripTo']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${bookingData['passengerName']} - Booked: $formattedDate'),
                      Text('Trip Date: $tripDate'),
                      Text('Seats: ${bookingData['seats']} - Total: €${bookingData['totalPrice']}'),
                      Text('Payment: ${bookingData['paymentMethod']}'),
                    ],
                  ),
                  trailing: _buildStatusChip(bookingData['status'] ?? 'pending'),
                  isThreeLine: true,
                  onTap: () => _showBookingDetails(bookingData),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        text = 'Confirmed';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _showBookingDetails(Map<String, dynamic> bookingData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passenger: ${bookingData['passengerName'] ?? 'Unknown'}'),
            Text('Trip: ${bookingData['tripFrom']} to ${bookingData['tripTo']}'),
            Text('Seats: ${bookingData['seats']}'),
            Text('Total Price: €${bookingData['totalPrice']}'),
            Text('Payment Method: ${bookingData['paymentMethod'] ?? 'N/A'}'),
            Text('Status: ${bookingData['status'] ?? 'pending'}'),
            if (bookingData['createdAt'] is Timestamp)
              Text('Booked: ${DateFormat.yMd().add_jm().format((bookingData['createdAt'] as Timestamp).toDate())}'),
            if (bookingData['tripDate'] is Timestamp)
              Text('Trip Date: ${DateFormat.yMd().add_jm().format((bookingData['tripDate'] as Timestamp).toDate())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MyTripsTab extends StatelessWidget {
  const _MyTripsTab();

  @override
  Widget build(BuildContext context) {
    // TODO: Load actual trips from Firebase
    final myTrips = [
      {
        'start': 'Berlin',
        'end': 'München',
        'date': '2024-01-15',
        'time': '14:30',
        'price': '35',
        'seats_available': 3,
        'total_seats': 4,
        'bookings': 1,
      },
      {
        'start': 'Hamburg',
        'end': 'Köln',
        'date': '2024-01-16',
        'time': '09:00',
        'price': '28',
        'seats_available': 2,
        'total_seats': 4,
        'bookings': 2,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: myTrips.length,
      itemBuilder: (context, index) {
        final trip = myTrips[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${trip['start']} to ${trip['end']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '€${trip['price']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${trip['date']} at ${trip['time']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.event_seat, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${trip['seats_available']}/${trip['total_seats']} seats available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Icon(Icons.people, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${trip['bookings']} bookings',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Edit trip
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit trip functionality coming soon!')),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: View bookings for this trip
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('View bookings functionality coming soon!')),
                          );
                        },
                        child: const Text('View Bookings'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context) {
    // TODO: Load actual bookings from Firebase
    final bookings = [
      {
        'trip': 'Berlin to München',
        'passenger': 'Max Mustermann',
        'date': '2024-01-15',
        'time': '14:30',
        'seat': 2,
        'status': 'confirmed',
      },
      {
        'trip': 'Hamburg to Köln',
        'passenger': 'Lisa Schmidt',
        'date': '2024-01-16',
        'time': '09:00',
        'seat': 1,
        'status': 'pending',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, size: 30, color: Colors.blue),
            ),
            title: Text(
              booking['trip'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${booking['passenger']} - ${booking['date']} at ${booking['time']}\nSeat: ${booking['seat']}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: booking['status'] == 'confirmed' ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking['status'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            isThreeLine: true,
            onTap: () {
              // TODO: Show booking details
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking details coming soon!')),
              );
            },
          ),
        );
      },
    );
  }
}

class _DriverProfileTab extends StatefulWidget {
  const _DriverProfileTab();

  @override
  State<_DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<_DriverProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  final TextEditingController _carYearController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = true;
  String _email = '';
  String? _licenseImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _surnameController.text = data['surname'] ?? '';
        _ageController.text = data['age'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _carModelController.text = data['car_model'] ?? '';
        _carColorController.text = data['car_color'] ?? '';
        _carYearController.text = data['car_year'] ?? '';
        _licenseNumberController.text = data['license_number'] ?? '';
        _email = data['email'] ?? '';
        _licenseImageUrl = data['license_image_url'];
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateUserProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'age': _ageController.text.trim(),
          'phone': _phoneController.text.trim(),
          'car_model': _carModelController.text.trim(),
          'car_color': _carColorController.text.trim(),
          'car_year': _carYearController.text.trim(),
          'license_number': _licenseNumberController.text.trim(),
        });
      }
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  Future<void> _uploadLicense() async {
    // TODO: Implement actual file upload to Firebase Storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('License upload functionality coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadUserData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildProfileForm(),
                const SizedBox(height: 24),
                _buildLicenseSection(),
                const SizedBox(height: 32),
                _buildLogoutButton(),
              ],
            ),
          );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.person, size: 60, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            _isEditing
                ? 'Editing Profile'
                : '${_nameController.text} ${_surnameController.text}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_email, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Driver',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextFormField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _surnameController,
                label: 'Surname',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _ageController,
                label: 'Age',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _phoneController,
                label: 'Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _carModelController,
                label: 'Car Model',
                icon: Icons.directions_car,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _carColorController,
                label: 'Car Color',
                icon: Icons.color_lens,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _carYearController,
                label: 'Car Year',
                icon: Icons.calendar_month,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _licenseNumberController,
                label: 'License Number',
                icon: Icons.card_membership,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        fillColor: _isEditing ? Colors.white : Colors.grey[200],
      ),
      keyboardType: keyboardType,
      validator: (value) =>
          value?.isEmpty ?? true ? '$label is required' : null,
    );
  }

  Widget _buildLicenseSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Driver License',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_licenseImageUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _licenseImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No license uploaded',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadLicense,
                icon: const Icon(Icons.upload),
                label: const Text('Upload License'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Log Out'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      },
    );
  }
} 