import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carsharing/core/providers/app_providers.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/points.dart';
import 'package:carsharing/features/booking/data/models/booking_requests.dart';

/// API Testing & Debugging Screen
/// 
/// Use this during development to test each endpoint without building full UI
/// Shows request/response for each API call with timing and status info
class ApiDebugScreen extends ConsumerStatefulWidget {
  const ApiDebugScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends ConsumerState<ApiDebugScreen> {
  final List<ApiTestResult> _results = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debugging Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() => _results.clear()),
            tooltip: 'Clear results',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Test Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                _buildTestButton(
                  'Search Trips',
                  _testSearchMatchingRoute,
                ),
                _buildTestButton(
                  'Offer Trip',
                  _testOfferTrip,
                ),
                _buildTestButton(
                  'Join Trip',
                  _testJoinTrip,
                ),
                _buildTestButton(
                  'Get Upcoming (Driver)',
                  _testGetUpcomingTripsForDriver,
                ),
                _buildTestButton(
                  'Get Bookings (Passenger)',
                  _testGetUpcomingBookings,
                ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text(
                      'Tap buttons above to test endpoints\n\nEach request shows:\n• Endpoint & method\n• Duration\n• Status\n• Request/Response',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[_results.length - 1 - index];
                      return ApiResultCard(result: result);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, Future<void> Function() onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => onPressed(),
      child: Text(label),
    );
  }

  /// Test: Search for matching route trips
  Future<void> _testSearchMatchingRoute() async {
    await _runTest(
      'GET /api/trips/search/matching-route',
      () => ref.read(tripRepositoryProvider).searchMatchingRoute(
        sourceLat: 52.52,
        sourceLon: 13.405,
        sourceRadiusKm: 5.0,
        destLat: 48.1351,
        destLon: 11.5820,
        destRadiusKm: 5.0,
        requestedSeats: 2,
        rideStartTime: DateTime.now().toUtc().toIso8601String(),
        effectiveUserId: 'user-123',
      ),
      requestInfo: {
        'sourceLat': 52.52,
        'sourceLon': 13.405,
        'sourceRadiusKm': 5.0,
        'destLat': 48.1351,
        'destLon': 11.5820,
        'destRadiusKm': 5.0,
        'requestedSeats': 2,
        'rideStartTime': 'now',
      },
    );
  }

  /// Test: Offer a new trip (driver)
  Future<void> _testOfferTrip() async {
    final request = OfferRideRequest(
      driverId: 'driver-123',
      vehicleNumber: 'ABC-1234',
      sourceAddress: const Points(
        latitude: 52.52,
        longitude: 13.405,
        placeAddress: 'Berlin',
      ),
      destinationAddress: const Points(
        latitude: 48.1351,
        longitude: 11.5820,
        placeAddress: 'Munich',
      ),
      tripStartDateTime: DateTime.parse('2024-01-15T10:00:00Z'),
      totalSeats: 4,
    );

    await _runTest(
      'POST /api/trips/offer',
      () => ref.read(tripRepositoryProvider).offerTrip(request),
      requestInfo: {
        'driverId': 'driver-123',
        'vehicleNumber': 'ABC-1234',
        'offeredSeat': 4,
      },
    );
  }

  /// Test: Join a trip (passenger)
  Future<void> _testJoinTrip() async {
    final request = JoinTripRequest(
      tripId: 'trip-123',
      passengerId: 'user-456',
      driverId: 'driver-123',
      pickupPoint: const Points(
        latitude: 52.52,
        longitude: 13.405,
        placeAddress: 'Berlin',
      ),
      destinationPoint: const Points(
        latitude: 48.1351,
        longitude: 11.5820,
        placeAddress: 'Munich',
      ),
      rideStartTime: '2024-01-15T10:00:00Z',
      requestedSeats: 2,
    );

    await _runTest(
      'POST /api/bookings/join',
      () => ref.read(bookingRepositoryProvider).joinTrip(request),
      requestInfo: {
        'tripId': 'trip-123',
        'passengerId': 'user-456',
        'requestedSeats': 2,
      },
    );
  }

  /// Test: Get driver's upcoming trips
  Future<void> _testGetUpcomingTripsForDriver() async {
    await _runTest(
      'GET /api/trips/upcoming/driver/{driverId}',
      () => ref.read(tripRepositoryProvider).getUpcomingTripsForDriver(
        'driver-123',
      ),
      requestInfo: {'driverId': 'driver-123'},
    );
  }

  /// Test: Get passenger's upcoming bookings
  Future<void> _testGetUpcomingBookings() async {
    await _runTest(
      'GET /api/bookings/upcoming/passenger/{passengerId}',
      () => ref.read(bookingRepositoryProvider)
          .getUpcomingBookingsForPassenger('user-456'),
      requestInfo: {'passengerId': 'user-456'},
    );
  }

  /// Generic test runner
  Future<void> _runTest(
    String endpoint,
    Future<dynamic> Function() testFn, {
    required Map<String, dynamic> requestInfo,
  }) async {
    setState(() => _isLoading = true);

    final startTime = DateTime.now();
    dynamic response;
    Exception? error;

    try {
      response = await testFn();
    } catch (e) {
      error = e as Exception;
    }

    final duration = DateTime.now().difference(startTime);

    final result = ApiTestResult(
      endpoint: endpoint,
      duration: duration,
      status: error == null ? 'Success' : 'Error',
      statusCode: error == null ? 200 : 500,
      requestInfo: requestInfo,
      responseData: response,
      error: error,
      timestamp: DateTime.now(),
    );

    setState(() {
      _results.add(result);
      _isLoading = false;
    });
  }
}

/// Test result model
class ApiTestResult {
  final String endpoint;
  final Duration duration;
  final String status;
  final int statusCode;
  final Map<String, dynamic> requestInfo;
  final dynamic responseData;
  final Exception? error;
  final DateTime timestamp;

  ApiTestResult({
    required this.endpoint,
    required this.duration,
    required this.status,
    required this.statusCode,
    required this.requestInfo,
    this.responseData,
    this.error,
    required this.timestamp,
  });
}

/// Display card for each test result
class ApiResultCard extends StatelessWidget {
  final ApiTestResult result;

  const ApiResultCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isError = result.error != null;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            result.endpoint,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isError ? Colors.red : Colors.green,
            ),
          ),
          subtitle: Text(
            '${result.duration.inMilliseconds}ms • ${result.timestamp.hour}:${result.timestamp.minute}:${result.timestamp.second}',
            style: const TextStyle(fontSize: 12),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Duration
                  _buildSection(
                    'Status',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.status} (${result.statusCode})',
                          style: TextStyle(
                            color: isError ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Duration: ${result.duration.inMilliseconds}ms',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Request Info
                  _buildSection('Request', _buildJsonDisplay(result.requestInfo)),

                  // Response or Error
                  if (result.error != null)
                    _buildSection(
                      'Error',
                      Text(
                        result.error.toString(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else if (result.responseData != null)
                    _buildSection(
                      'Response',
                      _buildJsonDisplay(result.responseData),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildJsonDisplay(dynamic data) {
    String jsonStr;
    if (data is String) {
      jsonStr = data;
    } else if (data is List) {
      jsonStr = 'List with ${data.length} items';
    } else {
      jsonStr = data.toString();
    }

    return Text(
      jsonStr,
      style: const TextStyle(
        fontFamily: 'Courier',
        fontSize: 12,
      ),
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
  }
}
