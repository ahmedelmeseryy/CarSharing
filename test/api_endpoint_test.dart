import 'package:dio/dio.dart';

/// Test script to verify Trip API endpoints
/// Run with: dart test/api_endpoint_test.dart
void main() async {
  print('🧪 Starting API Endpoint Tests...\n');
  
  // You'll need to replace this with a valid Firebase ID token
  const String testToken = 'YOUR_FIREBASE_ID_TOKEN_HERE';
  const String baseUrl = 'http://34.160.91.182';
  
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $testToken',
    },
    validateStatus: (status) => true, // Don't throw on any status
  ));

  // Test 1: Create a trip
  print('📝 Test 1: Create Trip (POST /trip-service/api/trips/offer)');
  print('─' * 60);
  
  final offerTripPayload = {
    'driverId': 'test-driver-123',
    'vehicleNumber': 'TEST-001',
    'sourceAddress': {
      'latitude': 50.8090106,
      'longitude': 8.7704695,
      'placeAddress': 'Marburg, Germany'
    },
    'destinationAddress': {
      'latitude': 50.1106444,
      'longitude': 8.6820917,
      'placeAddress': 'Frankfurt, Germany'
    },
    'tripStartDateTime': '2026-01-20T10:00:00.000Z',
    'offeredSeat': 3
  };
  
  try {
    final response = await dio.post(
      '/trip-service/api/trips/offer',
      data: offerTripPayload,
    );
    
    print('✅ Status: ${response.statusCode}');
    print('📦 Response:');
    print(response.data);
    print('');
  } catch (e) {
    print('❌ Error: $e\n');
  }

  // Test 2: Get upcoming trips for driver
  print('📝 Test 2: Get Driver Upcoming Trips (GET /trip-service/api/trips/upcoming/driver/{driverId})');
  print('─' * 60);
  
  try {
    final response = await dio.get(
      '/trip-service/api/trips/upcoming/driver/test-driver-123',
    );
    
    print('✅ Status: ${response.statusCode}');
    print('📦 Response:');
    print(response.data);
    print('');
  } catch (e) {
    print('❌ Error: $e\n');
  }

  // Test 3: Search trips near source
  print('📝 Test 3: Search Trips Near Source (GET /trip-service/api/trips/search/near-source)');
  print('─' * 60);
  
  try {
    final response = await dio.get(
      '/trip-service/api/trips/search/near-source',
      queryParameters: {
        'latitude': 50.8090106,
        'longitude': 8.7704695,
        'radiusKm': 10.0,
      },
    );
    
    print('✅ Status: ${response.statusCode}');
    print('📦 Response:');
    print(response.data);
    print('');
  } catch (e) {
    print('❌ Error: $e\n');
  }

  // Test 4: Search trips near destination
  print('📝 Test 4: Search Trips Near Destination (GET /trip-service/api/trips/search/near-destination)');
  print('─' * 60);
  
  try {
    final response = await dio.get(
      '/trip-service/api/trips/search/near-destination',
      queryParameters: {
        'latitude': 50.1106444,
        'longitude': 8.6820917,
        'radiusKm': 10.0,
      },
    );
    
    print('✅ Status: ${response.statusCode}');
    print('📦 Response:');
    print(response.data);
    print('');
  } catch (e) {
    print('❌ Error: $e\n');
  }

  // Test 5: Search matching route
  print('📝 Test 5: Search Matching Route (GET /trip-service/api/trips/search/matching-route)');
  print('─' * 60);
  
  try {
    final response = await dio.get(
      '/trip-service/api/trips/search/matching-route',
      queryParameters: {
        'sourceLat': 50.8090106,
        'sourceLon': 8.7704695,
        'sourceRadiusKm': 5.0,
        'destLat': 50.1106444,
        'destLon': 8.6820917,
        'destRadiusKm': 5.0,
        'rideStartTime': '2026-01-20T10:00:00.000Z',
        'requestedSeats': 2,
        'effectiveUserId': 'test-passenger-456',
      },
    );
    
    print('✅ Status: ${response.statusCode}');
    print('📦 Response:');
    print(response.data);
    print('');
  } catch (e) {
    print('❌ Error: $e\n');
  }

  // Test 6: Test without authentication
  print('📝 Test 6: Test Endpoint Without Auth (Should fail)');
  print('─' * 60);
  
  final dioNoAuth = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {'Content-Type': 'application/json'},
    validateStatus: (status) => true,
  ));
  
  try {
    final response = await dioNoAuth.get(
      '/trip-service/api/trips/upcoming/driver/test-driver-123',
    );
    
    print('Status: ${response.statusCode}');
    print('Response: ${response.data}');
    print('');
  } catch (e) {
    print('❌ Error: $e\n');
  }

  print('🏁 API Tests Complete!');
}
