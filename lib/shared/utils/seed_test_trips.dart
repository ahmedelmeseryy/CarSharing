import 'package:carsharing/core/network/dio_client.dart';
import 'package:carsharing/core/storage/secure_storage.dart';
import 'package:carsharing/features/trip/data/models/offer_ride_request.dart';
import 'package:carsharing/features/trip/data/models/points.dart';
import 'package:carsharing/features/trip/data/services/trip_api_service.dart';

/// Utility class to seed the database with test trips via the REST API.
class SeedTestTrips {
  static Future<void> addTestTrips() async {
    final userId = await TokenStorage().getUserId();
    if (userId == null || userId.isEmpty) {
      // ignore: avoid_print
      return;
    }

    final service = TripApiService(DioClient());

    final trips = [
      _makeRequest(userId,
          fromAddress: 'Hauptbahnhof, Berlin, Germany',
          fromLat: 52.5256, fromLon: 13.3695,
          toAddress: 'Marienplatz, Munich, Germany',
          toLat: 48.1374, toLon: 11.5755,
          daysFromNow: 3, hour: 14, seats: 4),
      _makeRequest(userId,
          fromAddress: 'Hamburg Hauptbahnhof, Hamburg, Germany',
          fromLat: 53.5511, fromLon: 10.0067,
          toAddress: 'Cologne Central Station, Cologne, Germany',
          toLat: 50.9375, toLon: 6.9603,
          daysFromNow: 5, hour: 9, seats: 3),
      _makeRequest(userId,
          fromAddress: 'Frankfurt Central Station, Frankfurt, Germany',
          fromLat: 50.1109, fromLon: 8.6821,
          toAddress: 'Stuttgart Hauptbahnhof, Stuttgart, Germany',
          toLat: 48.7833, toLon: 9.1833,
          daysFromNow: 7, hour: 16, seats: 2),
      _makeRequest(userId,
          fromAddress: 'Alexanderplatz, Berlin, Germany',
          fromLat: 52.5219, fromLon: 13.4132,
          toAddress: 'Dresden Hauptbahnhof, Dresden, Germany',
          toLat: 51.0493, toLon: 13.7381,
          daysFromNow: 2, hour: 11, seats: 5),
      _makeRequest(userId,
          fromAddress: 'Munich Central Station, Munich, Germany',
          fromLat: 48.1408, fromLon: 11.5595,
          toAddress: 'Salzburg Hauptbahnhof, Salzburg, Austria',
          toLat: 47.8095, toLon: 13.0550,
          daysFromNow: 4, hour: 13, seats: 3),
      _makeRequest(userId,
          fromAddress: 'Cologne Central Station, Cologne, Germany',
          fromLat: 50.9375, fromLon: 6.9603,
          toAddress: 'Düsseldorf Hauptbahnhof, Düsseldorf, Germany',
          toLat: 51.2203, toLon: 6.7949,
          daysFromNow: 1, hour: 10, seats: 4),
    ];

    for (final request in trips) {
      try {
        await service.offerTrip(request);
      } catch (e) {
        // ignore: avoid_print
      }
    }
    // ignore: avoid_print
  }

  static OfferRideRequest _makeRequest(
    String driverId, {
    required String fromAddress,
    required double fromLat,
    required double fromLon,
    required String toAddress,
    required double toLat,
    required double toLon,
    required int daysFromNow,
    required int hour,
    required int seats,
  }) {
    final now = DateTime.now();
    final departureDate = DateTime(now.year, now.month, now.day + daysFromNow, hour, 0);
    return OfferRideRequest(
      driverId: driverId,
      sourceAddress: Points(
        latitude: fromLat,
        longitude: fromLon,
        placeAddress: fromAddress,
      ),
      destinationAddress: Points(
        latitude: toLat,
        longitude: toLon,
        placeAddress: toAddress,
      ),
      tripStartDateTime: departureDate,
      totalSeats: seats,
    );
  }
}
