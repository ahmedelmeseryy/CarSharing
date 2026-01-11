import 'package:dio/dio.dart';
import 'dart:convert';

/// Quick test to verify trip was created and can be fetched
void main() async {
  const String token = 'eyJhbGciOiJSUzI1NiIsImtpZCI6ImQ4Mjg5MmZhMzJlY2QxM2E0ZTBhZWZlNjI4ZGQ5YWFlM2FiYThlMWUiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vY2Fyc2hhcmUtM2RjMjEiLCJhdWQiOiJjYXJzaGFyZS0zZGMyMSIsImF1dGhfdGltZSI6MTc2NzgyOTM0OCwidXNlcl9pZCI6IlJZaXdCV3pHUVRXaEt4OG5taEhOdXdCUXYyMzIiLCJzdWIiOiJSWWl3Qld6R1FUV2hLeDhubWhITnV3QlF2MjMyIiwiaWF0IjoxNzY3ODI5MzQ4LCJleHAiOjE3Njc4MzI5NDgsImVtYWlsIjoiZWxtZXNlcnk3MkBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJlbG1lc2VyeTcyQGdtYWlsLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.SLLoRoND_kIrRW5HrKzTkbmsLBqdi_FoPZPDRlnxV-Z9QwC3sxf-pOwbbB9YPGxJwSfcJz7rwWWuxg_lwcoKDypaN3TUldx67-Kn6IRIFjxo5HnLhoMzJ61A1PYRsKzxJl2mHepITNSVgNfDzg4x6JGBstK1O-Cj87IamRk_mLdqv-ww6RnUaTbpzfu99xlo0WhCdFCEJloIneVo_BwHIN34iEema-ntK0_3IbQwMROi04Nm6sOUrIGSGng_qQDnv72_JbXboyv96JOqnITyLPINA6u8BmcP8rJQkmqwK8kYp97ui2yldgm6MViY9Sax7aEY0sPtNtE8VvUqr-NDeQ';
  const String driverId = 'RYiwBWzGQTWhKx8nmhHNuwBQv232';
  
  final dio = Dio(BaseOptions(
    baseUrl: 'http://34.160.91.182',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    validateStatus: (status) => true,
  ));

  print('═' * 70);
  print('📋 Fetching Driver Upcoming Trips');
  print('═' * 70);
  
  final response = await dio.get('/trip-service/api/trips/upcoming/driver/$driverId');
  
  print('Status: ${response.statusCode}');
  
  if (response.statusCode == 200) {
    final data = response.data;
    if (data is Map && data['data'] is List) {
      final trips = data['data'] as List;
      print('✅ Found ${trips.length} trip(s)\n');
      
      for (var i = 0; i < trips.length; i++) {
        final trip = trips[i];
        print('Trip ${i + 1}:');
        print('  ID: ${trip['tripId']}');
        print('  Vehicle: ${trip['vehicleNumber']}');
        print('  From: ${trip['sourceAddress']['placeAddress']}');
        print('  To: ${trip['destinationAddress']['placeAddress']}');
        print('  Date: ${trip['tripStartDateTime']}');
        print('  Offered Seats: ${trip['offeredSeat']}');
        print('  Available Seats: ${trip['availableSeats']}');
        print('  Status: ${trip['tripStatus']}');
        print('');
      }
    }
  } else {
    print('❌ Error: ${response.statusCode}');
    print(response.data);
  }
}
