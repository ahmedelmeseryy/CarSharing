import 'package:carsharing/utils/seed_test_trips.dart';
import 'package:flutter/material.dart';

/// Admin page to seed the database with test trips
/// This is useful for testing route matching and search functionality
class SeedTripsPage extends StatefulWidget {
  const SeedTripsPage({super.key});

  @override
  State<SeedTripsPage> createState() => _SeedTripsPageState();
}

class _SeedTripsPageState extends State<SeedTripsPage> {
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _addTestTrips() async {
    setState(() {
      _isLoading = true;
      _message = null;
      _isSuccess = false;
    });

    try {
      await SeedTestTrips.addTestTrips();
      setState(() {
        _isLoading = false;
        _message = 'Successfully added 10 test trips to the database!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error: $e';
        _isSuccess = false;
      });
    }
  }

  Future<void> _clearAllTrips() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Trips'),
        content: const Text(
          'Are you sure you want to delete all your trips? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await SeedTestTrips.clearAllTrips();
      setState(() {
        _isLoading = false;
        _message = 'All trips cleared successfully';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error: $e';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Test Trips'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Test Data Generator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This will add 10 test trips to your database with:',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem('✓ Exact addresses with coordinates'),
                    _buildInfoItem('✓ Intermediate stops'),
                    _buildInfoItem('✓ Various routes across Germany'),
                    _buildInfoItem('✓ Different dates and times'),
                    _buildInfoItem('✓ Different prices and seat availability'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _addTestTrips,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle),
              label: Text(_isLoading ? 'Adding Trips...' : 'Add 10 Test Trips'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _clearAllTrips,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear All My Trips'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 24),
              Card(
                color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.error,
                        color: _isSuccess ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Test Trips Included:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTripInfo('Berlin → Munich', 'Via Nuremberg', '3 days', '€35.50'),
            _buildTripInfo('Hamburg → Cologne', 'Via Bremen, Dortmund', '5 days', '€28.00'),
            _buildTripInfo('Frankfurt → Stuttgart', 'Direct', '7 days', '€25.00'),
            _buildTripInfo('Berlin → Dresden', 'Via Cottbus', '2 days', '€22.50'),
            _buildTripInfo('Munich → Salzburg', 'Via Rosenheim', '4 days', '€30.00'),
            _buildTripInfo('Cologne → Düsseldorf', 'Direct', '1 day', '€15.00'),
            _buildTripInfo('Hamburg → Berlin', 'Via Lübeck', '6 days', '€40.00'),
            _buildTripInfo('Stuttgart → Frankfurt', 'Via Heidelberg, Mannheim', '8 days', '€32.00'),
            _buildTripInfo('Berlin → Potsdam', 'Direct', 'Today +2h', '€12.00'),
            _buildTripInfo('Berlin → Vienna', 'Via Leipzig, Dresden, Prague', '10 days', '€55.00'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(color: Colors.blue.shade700),
      ),
    );
  }

  Widget _buildTripInfo(String route, String stops, String date, String price) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.directions_car, color: Colors.blue),
        title: Text(route, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$stops • $date'),
        trailing: Text(
          price,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ),
    );
  }
}
