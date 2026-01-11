import 'package:dio/dio.dart';
import 'dart:convert';

/// Minimal test to isolate the 400 error
void main() async {
  const String token = 'eyJhbGciOiJSUzI1NiIsImtpZCI6ImQ4Mjg5MmZhMzJlY2QxM2E0ZTBhZWZlNjI4ZGQ5YWFlM2FiYThlMWUiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vY2Fyc2hhcmUtM2RjMjEiLCJhdWQiOiJjYXJzaGFyZS0zZGMyMSIsImF1dGhfdGltZSI6MTc2NzgyODM0OCwidXNlcl9pZCI6IlJZaXdCV3pHUVRXaEt4OG5taEhOdXdCUXYyMzIiLCJzdWIiOiJSWWl3Qld6R1FUV2hLeDhubWhITnV3QlF2MjMyIiwiaWF0IjoxNzY3ODI4MzQ4LCJleHAiOjE3Njc4MzE5NDgsImVtYWlsIjoiZWxtZXNlcnk3MkBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJlbG1lc2VyeTcyQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.Os65EkCtxgBe_eAQdhwYAUjs91_jhuGfTyXZo6zxjT8-mdJO6n3xz6DUYhG1Lr0ADfyBfIoNk2iBTpxvFRtuuoDTWABspyv0OXPj1JrBwA71dDoPzXEYkO445FbedTxKoQXJZ0BtIqec3S6nYZWvyrlP7xSU6yLNlydBJIR9ceCndNuSieot0yc-uPj95HGGcCddiOdfm_w_fQFj6oJxg6oFt6MVVzkn16hzlR9UhLp6enP39x2r62ZLzPeCdhpLPNY2BRetFOt72abmuZ7Wt00fXTv92ZCMXsVYqr4UIF1wwBkJdkU614bgTkif68CCeFtvxjR-4BrQXpAXT8-Cnw';
  
  final dio = Dio(BaseOptions(
    baseUrl: 'http://34.160.91.182',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    validateStatus: (status) => true,
  ));

  print('Testing different payload variations...\n');
  
  // Test 1: With placeId included
  await testPayload(dio, 'With placeId (null)', {
    'driverId': 'RYiwBWzGQTWhKx8nmhHNuwBQv232',
    'vehicleNumber': 'TEST-001',
    'sourceAddress': {
      'latitude': 50.8090106,
      'longitude': 8.7704695,
      'placeId': null,
      'placeAddress': 'Marburg, Germany'
    },
    'destinationAddress': {
      'latitude': 50.1106444,
      'longitude': 8.6820917,
      'placeId': null,
      'placeAddress': 'Frankfurt, Germany'
    },
    'tripStartDateTime': '2026-01-25T14:30:00.000Z',
    'offeredSeat': 4
  });

  // Test 2: Without placeId field at all
  await testPayload(dio, 'Without placeId field', {
    'driverId': 'RYiwBWzGQTWhKx8nmhHNuwBQv232',
    'vehicleNumber': 'TEST-002',
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
    'tripStartDateTime': '2026-01-25T15:00:00.000Z',
    'offeredSeat': 3
  });

  // Test 3: Minimal required fields only
  await testPayload(dio, 'Minimal fields only', {
    'driverId': 'RYiwBWzGQTWhKx8nmhHNuwBQv232',
    'vehicleNumber': 'TEST-003',
    'sourceAddress': {
      'latitude': 50.8090106,
      'longitude': 8.7704695,
    },
    'destinationAddress': {
      'latitude': 50.1106444,
      'longitude': 8.6820917,
    },
    'tripStartDateTime': '2026-01-25T16:00:00.000Z',
    'offeredSeat': 2
  });

  // Test 4: Different date format
  await testPayload(dio, 'ISO date format without milliseconds', {
    'driverId': 'RYiwBWzGQTWhKx8nmhHNuwBQv232',
    'vehicleNumber': 'TEST-004',
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
    'tripStartDateTime': '2026-01-25T17:00:00Z',
    'offeredSeat': 4
  });
}

Future<void> testPayload(Dio dio, String testName, Map<String, dynamic> payload) async {
  print('─' * 70);
  print('Test: $testName');
  print('Payload: ${JsonEncoder.withIndent("  ").convert(payload)}');
  
  try {
    final response = await dio.post('/trip-service/api/trips/offer', data: payload);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ SUCCESS! Status: ${response.statusCode}');
      print('Response: ${JsonEncoder.withIndent("  ").convert(response.data)}');
    } else {
      print('❌ FAILED! Status: ${response.statusCode}');
      print('Response: ${response.data}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
  
  print('');
}
