import 'package:flutter_test/flutter_test.dart';
import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/features/trip/data/services/trip_api_service.dart';
import 'package:carsharing/features/trip/data/repositories/trip_repository_impl.dart';
import 'package:carsharing/core/storage/secure_storage.dart';

/// Debug test for trip search - helps identify 400 errors
/// Run with: flutter test test/trip_search_debug_test.dart
void main() {
  group('Trip Search Debug Tests', () {
    late DioClient dioClient;
    late TripApiService tripApiService;
    late TripRepositoryImpl tripRepository;

    setUpAll(() async {
      // Initialize storage and DioClient
      final tokenStorage = TokenStorage();
      final token = await tokenStorage.getAccessToken();
      
      print('🔑 Token available: ${token != null && token.isNotEmpty}');
      if (token != null && token.isNotEmpty) {
        print('🔑 Token (first 50 chars): ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
      }
      
      dioClient = DioClient(tokenStorage: tokenStorage);
      tripApiService = TripApiService(dioClient);
      tripRepository = TripRepositoryImpl(tripApiService);
    });

    test('Test 1: Search matching route with ALL params', () async {
      print('\n========================================');
      print('TEST 1: Full search with all parameters');
      print('========================================');
      
      try {
        final trips = await tripRepository.searchMatchingRoute(
          sourceLat: 50.8090106,
          sourceLon: 8.7704695,
          sourceRadiusKm: 10.0,
          destLat: 50.1106444,
          destLon: 8.6820917,
          destRadiusKm: 10.0,
          requestedSeats: 1,
          rideStartTime: DateTime.now().toUtc().toIso8601String(),
          effectiveUserId: 'test-user-id',
        );
        
        print('✅ Success! Found ${trips.length} trips');
        for (var trip in trips) {
          print('  - Trip ${trip.tripId}: ${trip.sourceAddress.placeAddress} → ${trip.destinationAddress.placeAddress}');
        }
      } catch (e) {
        print('❌ Error: $e');
        rethrow;
      }
    });

    test('Test 2: Search matching route WITHOUT optional params', () async {
      print('\n========================================');
      print('TEST 2: Minimal search (no optional params)');
      print('========================================');
      
      try {
        final trips = await tripRepository.searchMatchingRoute(
          sourceLat: 50.8090106,
          sourceLon: 8.7704695,
          sourceRadiusKm: 10.0,
          destLat: 50.1106444,
          destLon: 8.6820917,
          destRadiusKm: 10.0,
          rideStartTime: DateTime.now().toUtc().toIso8601String(),
          requestedSeats: 1,
          effectiveUserId: 'test_user',
        );
        
        print('✅ Success! Found ${trips.length} trips');
        for (var trip in trips) {
          print('  - Trip ${trip.tripId}: ${trip.sourceAddress.placeAddress} → ${trip.destinationAddress.placeAddress}');
        }
      } catch (e) {
        print('❌ Error: $e');
        rethrow;
      }
    });

    test('Test 3: Search near source only', () async {
      print('\n========================================');
      print('TEST 3: Near source search');
      print('========================================');
      
      try {
        final trips = await tripRepository.searchNearSource(
          sourceLat: 50.8090106,
          sourceLon: 8.7704695,
          radiusKm: 10.0,
        );
        
        print('✅ Success! Found ${trips.length} trips near source');
        for (var trip in trips) {
          print('  - Trip ${trip.tripId}: ${trip.sourceAddress.placeAddress}');
        }
      } catch (e) {
        print('❌ Error: $e');
        rethrow;
      }
    });

    test('Test 4: Search near destination only', () async {
      print('\n========================================');
      print('TEST 4: Near destination search');
      print('========================================');
      
      try {
        final trips = await tripRepository.searchNearDestination(
          destLat: 50.1106444,
          destLon: 8.6820917,
          radiusKm: 10.0,
        );
        
        print('✅ Success! Found ${trips.length} trips near destination');
        for (var trip in trips) {
          print('  - Trip ${trip.tripId}: → ${trip.destinationAddress.placeAddress}');
        }
      } catch (e) {
        print('❌ Error: $e');
        rethrow;
      }
    });

    test('Test 5: Direct API call with logging', () async {
      print('\n========================================');
      print('TEST 5: Direct API call to see raw request');
      print('========================================');
      
      try {
        print('Making request with params:');
        print('  sourceLat: 50.8090106');
        print('  sourceLon: 8.7704695');
        print('  sourceRadiusKm: 10.0');
        print('  destLat: 50.1106444');
        print('  destLon: 8.6820917');
        print('  destRadiusKm: 10.0');
        print('  requestedSeats: 1');
        print('  rideStartTime: ${DateTime.now().toUtc().toIso8601String()}');
        
        final response = await tripApiService.searchMatchingRoute(
          sourceLat: 50.8090106,
          sourceLon: 8.7704695,
          sourceRadiusKm: 10.0,
          destLat: 50.1106444,
          destLon: 8.6820917,
          destRadiusKm: 10.0,
          rideStartTime: DateTime.now().toUtc().toIso8601String(),
          requestedSeats: 1,
          effectiveUserId: 'test_user',
        );
        
        print('✅ Response success: ${response.isSuccess}');
        print('✅ Response message: ${response.message ?? "N/A"}');
        print('✅ Found ${response.data?.length ?? 0} trips');
      } catch (e) {
        print('❌ Error: $e');
        rethrow;
      }
    });
  });
}
