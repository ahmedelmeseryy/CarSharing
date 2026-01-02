import 'dart:math';

/// Model for a trip with distance information
class TripWithDistance {
  final Map<String, dynamic> trip;
  final double distanceKm;

  TripWithDistance({
    required this.trip,
    required this.distanceKm,
  });

  /// Get the pickup location from the trip
  Map<String, dynamic>? get pickupLocation => trip['pickupLocation'];

  /// Get the start location (fallback for address-based trips)
  String? get startAddress => trip['start'];

  /// Get the destination location
  String? get destinationAddress => trip['end'];

  /// Get the trip ID
  String get tripId => trip['id'] ?? '${startAddress}-${destinationAddress}';
}

/// Service for searching trips by distance
class TripSearchService {
  /// Earth's radius in kilometers
  static const double _earthRadiusKm = 6371.0;

  /// Calculate the great-circle distance between two geographic coordinates
  /// using the Haversine formula.
  ///
  /// Returns distance in kilometers.
  ///
  /// Parameters:
  ///   - lat1, lon1: User's location (latitude, longitude in degrees)
  ///   - lat2, lon2: Destination location (latitude, longitude in degrees)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Filter and rank trips by distance from a user's location.
  ///
  /// Parameters:
  ///   - trips: List of trip objects from Firestore
  ///   - userLat, userLon: User's location coordinates
  ///   - radiusKm: Maximum distance in kilometers (default 10 km)
  ///
  /// Returns: List of [TripWithDistance] objects sorted by distance (nearest first).
  ///          Only trips within the radius are included.
  static List<TripWithDistance> filterAndRankByDistance(
    List<dynamic> trips,
    double userLat,
    double userLon, {
    double radiusKm = 10.0,
  }) {
    final results = <TripWithDistance>[];

    for (final trip in trips) {
      // Try to extract pickup location from the trip
      final pickupLocation = trip['pickupLocation'];

      if (pickupLocation != null) {
        // Trip has structured location data with lat/lon
        final double? tripLat = pickupLocation['latitude'];
        final double? tripLon = pickupLocation['longitude'];

        if (tripLat != null && tripLon != null) {
          final distance = calculateDistance(userLat, userLon, tripLat, tripLon);

          if (distance <= radiusKm) {
            results.add(TripWithDistance(
              trip: trip,
              distanceKm: distance,
            ));
          }
        }
      }
      // Note: If no pickupLocation with coordinates, the trip is skipped.
      // In future, could add fallback to geocode 'start' address if needed.
    }

    // Sort by distance (nearest first)
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return results;
  }

  /// Format distance for display (e.g., "2.5 km" or "500 m")
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).toStringAsFixed(0);
      return '$meters m';
    } else {
      final km = distanceKm.toStringAsFixed(1);
      return '$km km';
    }
  }

  /// Get the suggested radius in km (e.g., for UI selection)
  static const List<double> suggestedRadii = [2.0, 5.0, 10.0, 20.0];
}
