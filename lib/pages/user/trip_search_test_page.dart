import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';

/// Manual test page for trip search
/// Add this to your dashboard to access it
class TripSearchTestPage extends ConsumerStatefulWidget {
  const TripSearchTestPage({super.key});

  @override
  ConsumerState<TripSearchTestPage> createState() => _TripSearchTestPageState();
}

class _TripSearchTestPageState extends ConsumerState<TripSearchTestPage> {
  final _logs = <String>[];
  bool _isLoading = false;

  void _log(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
    });
    print(message);
  }

  Future<void> _testSearch1() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _log('🧪 TEST 1: Search with ALL parameters');
    _log('Source: 50.8090106, 8.7704695');
    _log('Dest: 50.1106444, 8.6820917');
    _log('Radius: 10 km');
    _log('Seats: 1');
    _log('Time: ${DateTime.now().toUtc().toIso8601String()}');

    try {
      final userId = await ref.read(secureStorageProvider).getUserId() ?? '';
      if (userId.isEmpty) {
        _log('❌ ERROR: Missing userId in storage.');
        return;
      }
      final repository = ref.read(tripRepositoryProvider);
      final trips = await repository.searchMatchingRoute(
        sourceLat: 50.8090106,
        sourceLon: 8.7704695,
        sourceRadiusKm: 10.0,
        destLat: 50.1106444,
        destLon: 8.6820917,
        destRadiusKm: 10.0,
        requestedSeats: 1,
        rideStartTime: DateTime.now().toUtc().toIso8601String(),
        effectiveUserId: userId,
      );

      _log('✅ SUCCESS! Found ${trips.length} trips');
      for (var trip in trips) {
        _log('  📍 ${trip.sourceAddress.placeAddress} → ${trip.destinationAddress.placeAddress}');
        _log('     Seats: ${trip.availableSeats}, Price: €${trip.estimatedFare.toStringAsFixed(2)}');
      }
    } catch (e, stack) {
      _log('❌ ERROR: $e');
      _log('Stack: ${stack.toString().split('\n').take(3).join('\n')}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSearch2() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _log('🧪 TEST 2: Search WITHOUT optional parameters');
    _log('Source: 50.8090106, 8.7704695');
    _log('Dest: 50.1106444, 8.6820917');
    _log('Radius: 10 km');

    try {
      final userId = await ref.read(secureStorageProvider).getUserId() ?? '';
      if (userId.isEmpty) {
        _log('❌ ERROR: Missing userId in storage.');
        return;
      }
      final repository = ref.read(tripRepositoryProvider);
      final trips = await repository.searchMatchingRoute(
        sourceLat: 50.8090106,
        sourceLon: 8.7704695,
        sourceRadiusKm: 10.0,
        destLat: 50.1106444,
        destLon: 8.6820917,
        destRadiusKm: 10.0,
        requestedSeats: 1,
        rideStartTime: DateTime.now().toUtc().toIso8601String(),
        effectiveUserId: userId,
      );

      _log('✅ SUCCESS! Found ${trips.length} trips');
      for (var trip in trips) {
        _log('  📍 ${trip.sourceAddress.placeAddress} → ${trip.destinationAddress.placeAddress}');
      }
    } catch (e, stack) {
      _log('❌ ERROR: $e');
      _log('Stack: ${stack.toString().split('\n').take(3).join('\n')}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSearch3() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _log('🧪 TEST 3: Search near SOURCE only');
    _log('Source: 50.8090106, 8.7704695');
    _log('Radius: 10 km');

    try {
      final repository = ref.read(tripRepositoryProvider);
      final trips = await repository.searchNearSource(
        sourceLat: 50.8090106,
        sourceLon: 8.7704695,
        radiusKm: 10.0,
      );

      _log('✅ SUCCESS! Found ${trips.length} trips near source');
      for (var trip in trips) {
        _log('  📍 From: ${trip.sourceAddress.placeAddress}');
      }
    } catch (e, stack) {
      _log('❌ ERROR: $e');
      _log('Stack: ${stack.toString().split('\n').take(3).join('\n')}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Search Test'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSearch1,
                  child: const Text('Test 1: Full Search (all params)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSearch2,
                  child: const Text('Test 2: Minimal Search (no optional)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSearch3,
                  child: const Text('Test 3: Near Source Only'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() => _logs.clear()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Clear Logs'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: Container(
              color: Colors.black87,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  final color = log.contains('❌')
                      ? Colors.red
                      : log.contains('✅')
                          ? Colors.green
                          : log.contains('🧪')
                              ? Colors.yellow
                              : Colors.white70;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: color,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
