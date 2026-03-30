import 'package:dio/dio.dart';
import 'dart:convert';

/// Live API test using the actual token from logs
/// Run with: dart test/live_api_test.dart
void main() async {
  print('🧪 Live API Endpoint Tests\n');
  
  // Token from your logs (expires in ~1 hour)
  const String token = 'eyJhbGciOiJSUzI1NiIsImtpZCI6ImQ4Mjg5MmZhMzJlY2QxM2E0ZTBhZWZlNjI4ZGQ5YWFlM2FiYThlMWUiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vY2Fyc2hhcmUtM2RjMjEiLCJhdWQiOiJjYXJzaGFyZS0zZGMyMSIsImF1dGhfdGltZSI6MTc2NzgyODM0OCwidXNlcl9pZCI6IlJZaXdCV3pHUVRXaEt4OG5taEhOdXdCUXYyMzIiLCJzdWIiOiJSWWl3Qld6R1FUV2hLeDhubWhITnV3QlF2MjMyIiwiaWF0IjoxNzY3ODI4MzQ4LCJleHAiOjE3Njc4MzE5NDgsImVtYWlsIjoiZWxtZXNlcnk3MkBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJlbG1lc2VyeTcyQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.Os65EkCtxgBe_eAQdhwYAUjs91_jhuGfTyXZo6zxjT8-mdJO6n3xz6DUYhG1Lr0ADfyBfIoNk2iBTpxvFRtuuoDTWABspyv0OXPj1JrBwA71dDoPzXEYkO445FbedTxKoQXJZ0BtIqec3S6nYZWvyrlP7xSU6yLNlydBJIR9ceCndNuSieot0yc-uPj95HGGcCddiOdfm_w_fQFj6oJxg6oFt6MVVzkn16hzlR9UhLp6enP39x2r62ZLzPeCdhpLPNY2BRetFOt72abmuZ7Wt00fXTv92ZCMXsVYqr4UIF1wwBkJdkU614bgTkif68CCeFtvxjR-4BrQXpAXT8-Cnw';
  
  const String baseUrl = 'http://35.186.208.67';
  const String driverId = 'RYiwBWzGQTWhKx8nmhHNuwBQv232';
  
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    validateStatus: (status) => true,
  ));

  // Test 1: Create a trip
  await testCreateTrip(dio, driverId);
  
  // Test 2: Get upcoming trips
  await testGetUpcomingTrips(dio, driverId);
  
  // Test 3: Search near source
  await testSearchNearSource(dio);
  
  print('🏁 Tests Complete!\n');
}

Future<void> testCreateTrip(Dio dio, String driverId) async {
  print('═' * 70);
  print('📝 TEST: Create Trip (POST /trip-service/api/trips/offer)');
  print('═' * 70);
  
  final payload = {
    'driverId': driverId,
    'vehicleNumber': 'API-TEST-001',
    'sourceAddress': {
      'latitude': 50.8090106,
      'longitude': 8.7704695,
      'placeAddress': 'Marburg, Hesse, Germany'
    },
    'destinationAddress': {
      'latitude': 50.1106444,
      'longitude': 8.6820917,
      'placeAddress': 'Frankfurt, Hesse, Germany'
    },
    'tripStartDateTime': '2026-01-25T14:30:00.000Z',
    'offeredSeat': 4
  };
  
  print('📤 Request Payload:');
  print(JsonEncoder.withIndent('  ').convert(payload));
  print('');
  
  try {
    final response = await dio.post(
      '/trip-service/api/trips/offer',
      data: payload,
    );
    
    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body:');
    print(JsonEncoder.withIndent('  ').convert(response.data));
    print('');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ SUCCESS: Trip created successfully!\n');
    } else {
      print('⚠️  WARNING: Unexpected status code\n');
    }
  } catch (e) {
    print('❌ ERROR: $e\n');
  }
}

Future<void> testGetUpcomingTrips(Dio dio, String driverId) async {
  print('═' * 70);
  print('📝 TEST: Get Upcoming Trips (GET /trip-service/api/trips/upcoming/driver/$driverId)');
  print('═' * 70);
  
  try {
    final response = await dio.get(
      '/trip-service/api/trips/upcoming/driver/$driverId',
    );
    
    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body:');
    print(JsonEncoder.withIndent('  ').convert(response.data));
    print('');
    
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data['data'] is List) {
        final trips = data['data'] as List;
        print('✅ SUCCESS: Found ${trips.length} trip(s)\n');
      } else {
        print('✅ SUCCESS: Retrieved trips data\n');
      }
    } else {
      print('⚠️  WARNING: Unexpected status code\n');
    }
  } catch (e) {
    print('❌ ERROR: $e\n');
  }
}

Future<void> testSearchNearSource(Dio dio) async {
  print('═' * 70);
  print('📝 TEST: Search Near Source (GET /trip-service/api/trips/search/near-source)');
  print('═' * 70);
  
  final params = {
    'latitude': 50.8090106,
    'longitude': 8.7704695,
    'radiusKm': 20.0,
  };
  
  print('📤 Query Parameters:');
  print(JsonEncoder.withIndent('  ').convert(params));
  print('');
  
  try {
    final response = await dio.get(
      '/trip-service/api/trips/search/near-source',
      queryParameters: params,
    );
    
    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response Body:');
    print(JsonEncoder.withIndent('  ').convert(response.data));
    print('');
    
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data['data'] is List) {
        final trips = data['data'] as List;
        print('✅ SUCCESS: Found ${trips.length} trip(s) near Marburg\n');
      } else {
        print('✅ SUCCESS: Retrieved search results\n');
      }
    } else {
      print('⚠️  WARNING: Unexpected status code\n');
    }
  } catch (e) {
    print('❌ ERROR: $e\n');
  }
}
